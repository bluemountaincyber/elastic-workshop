#!/bin/bash

# Install docker and docker-compose
yum update -y
yum install docker -y
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -O /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
usermod -aG docker ec2-user
systemctl enable docker
systemctl start docker

# Adjust vm.max_map_count
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p

# Create Logstash configuration
mkdir /home/ec2-user/logstash
cat << 'EOF' > /home/ec2-user/logstash/logstash.yml
config:
  reload:
    automatic: true
    interval: 3s
EOF

# Create Logstash pipeline
cat << 'EOF' > /home/ec2-user/logstash/logstash.conf
input {
  kinesis {
    kinesis_stream_name => "AWS_Logs"
    region => "${REGION}"
    codec => cloudwatch_logs
  }
}

filter {
  if [logGroup] == "opensearch/syslog" {
    grok {
      match => { "message" => "%%{SYSLOGBASE}" }
    }
    date {
      timezone => "Etc/UTC"
      match => ["timestamp", "MMM dd HH:mm:ss", "MMM d HH:mm:ss"]
      target => "@timestamp"
    }
    mutate {
      remove_field => [ "messageType", "subscriptionFilters", "timestamp" ]
    }
  }

  if [logGroup] == "opensearch/apache-access-log" {
    grok {
      match => { "message" => "%%{COMBINEDAPACHELOG}" }
    }
    date {
      timezone => "Etc/UTC"
      match => ["timestamp", "dd/MMM/yyyy:HH:mm:ss +0000"]
      target => "@timestamp"
    }
    mutate {
      remove_field => [ "messageType", "subscriptionFilters", "timestamp" ]
    }
  }

  if [logGroup] == "opensearch/cloudtrail" {
    json {
      source => "message"
    }
    mutate {
      remove_field => [ "apiVersion", "messageType", "subscriptionFilters" ]
    }
  }
}

output {
  opensearch {
     hosts => ["https://opensearch-node1:9200","https://opensearch-node2:9200"]
     index => "awslogs-%%{+YYYY.MM.dd}"
     user => "admin"
     password => "admin"
     ssl => true
     ssl_certificate_verification => false
   }
}
EOF

# Create Logstash Dockerfile
cat << 'EOF' > /home/ec2-user/logstash/Dockerfile
FROM opensearchproject/logstash-oss-with-opensearch-output-plugin:7.16.2
RUN rm -f /usr/share/logstash/pipeline/logstash.conf && \
  bin/logstash-plugin install logstash-input-kinesis && \
  bin/logstash-plugin install logstash-codec-cloudwatch_logs
EOF

# Create docker-compose.yml
cat << 'EOF' > /home/ec2-user/docker-compose.yml
version: '3'
services:
  opensearch-node1:
    image: opensearchproject/opensearch:1.3.1
    container_name: opensearch-node1
    environment:
      - cluster.name=opensearch-cluster
      - node.name=opensearch-node1
      - discovery.seed_hosts=opensearch-node1,opensearch-node2
      - cluster.initial_master_nodes=opensearch-node1,opensearch-node2
      - bootstrap.memory_lock=true # along with the memlock settings below, disables swapping
      - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m" # minimum and maximum Java heap size, recommend setting both to 50% of system RAM
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536 # maximum number of open files for the OpenSearch user, set to at least 65536 on modern systems
        hard: 65536
    volumes:
      - opensearch-data1:/usr/share/opensearch/data
    ports:
      - 9200:9200
      - 9600:9600 # required for Performance Analyzer
    networks:
      - opensearch-net
    restart: always
  opensearch-node2:
    image: opensearchproject/opensearch:1.3.1
    container_name: opensearch-node2
    environment:
      - cluster.name=opensearch-cluster
      - node.name=opensearch-node2
      - discovery.seed_hosts=opensearch-node1,opensearch-node2
      - cluster.initial_master_nodes=opensearch-node1,opensearch-node2
      - bootstrap.memory_lock=true
      - "OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m"
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - opensearch-data2:/usr/share/opensearch/data
    networks:
      - opensearch-net
    restart: always
  opensearch-dashboards:
    image: opensearchproject/opensearch-dashboards:1.3.0
    container_name: opensearch-dashboards
    ports:
      - 5601:5601
    expose:
      - "5601"
    environment:
      OPENSEARCH_HOSTS: '["https://opensearch-node1:9200","https://opensearch-node2:9200"]' # must be a string with no spaces when specified as an environment variable
    networks:
      - opensearch-net
    restart: always
  opensearch-logstash:
    build:
      context: ./logstash
    container_name: opensearch-logstash
    environment:
      LS_JAVA_OPTS: "-Xmx256m -Xms256m"
    volumes:
      - /home/ec2-user/logstash/logstash.conf:/usr/share/logstash/pipeline/logstash.conf
      - /home/ec2-user/logstash/logstash.yml:/usr/share/logstash/config/logstash.yml
    networks:
      - opensearch-net
    restart: always

volumes:
  opensearch-data1:
  opensearch-data2:

networks:
  opensearch-net:
EOF
chown ec2-user:ec2-user /home/ec2-user/docker-compose.yml

# Adjust permissions
chown -R ec2-user:ec2-user /home/ec2-user

# Start up Opensearch
sudo -u ec2-user -i /usr/local/bin/docker-compose up -d