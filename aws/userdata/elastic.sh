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

# Get host URL
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
URL=$(curl -s -H "X-aws-ec2-metadata-token: $$TOKEN" http://169.254.169.254/latest/meta-data/public-hostname)

# Create .env file
mkdir /home/ec2-user/elastic
cat << EOF > /home/ec2-user/elastic/.env
ELASTIC_PASSWORD=${PASSWORD}
KIBANA_PASSWORD=${PASSWORD}
STACK_VERSION=8.1.3
CLUSTER_NAME=es-cluster
LICENSE=basic
ES_PORT=9200
KIBANA_PORT=5601
MEM_LIMIT=1073741824
KIBANA_URL=http://$$URL
EOF

# Create docker-compose.yml
cat << 'EOF' > /home/ec2-user/elastic/docker-compose.yml
version: "2.2"

services:
  setup:
    image: docker.elastic.co/elasticsearch/elasticsearch:$${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
    user: "0"
    command: >
      bash -c '
        if [ x$${ELASTIC_PASSWORD} == x ]; then
          echo "Set the ELASTIC_PASSWORD environment variable in the .env file";
          exit 1;
        elif [ x$${KIBANA_PASSWORD} == x ]; then
          echo "Set the KIBANA_PASSWORD environment variable in the .env file";
          exit 1;
        fi;
        if [ ! -f config/certs/ca.zip ]; then
          echo "Creating CA";
          bin/elasticsearch-certutil ca --silent --pem -out config/certs/ca.zip;
          unzip config/certs/ca.zip -d config/certs;
        fi;
        if [ ! -f config/certs/certs.zip ]; then
          echo "Creating certs";
          echo -ne \
          "instances:\n"\
          "  - name: es01\n"\
          "    dns:\n"\
          "      - es01\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          "  - name: es02\n"\
          "    dns:\n"\
          "      - es02\n"\
          "      - localhost\n"\
          "    ip:\n"\
          "      - 127.0.0.1\n"\
          > config/certs/instances.yml;
          bin/elasticsearch-certutil cert --silent --pem -out config/certs/certs.zip --in config/certs/instances.yml --ca-cert config/certs/ca/ca.crt --ca-key config/certs/ca/ca.key;
          unzip config/certs/certs.zip -d config/certs;
        fi;
        echo "Setting file permissions"
        chown -R root:root config/certs;
        find . -type d -exec chmod 750 \{\} \;;
        find . -type f -exec chmod 640 \{\} \;;
        echo "Waiting for Elasticsearch availability";
        until curl -s --cacert config/certs/ca/ca.crt https://es01:9200 | grep -q "missing authentication credentials"; do sleep 30; done;
        echo "Setting kibana_system password";
        until curl -s -X POST --cacert config/certs/ca/ca.crt -u elastic:$${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/user/kibana_system/_password -d "{\"password\":\"$${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;
        echo "All done!";
      '
    healthcheck:
      test: ["CMD-SHELL", "[ -f config/certs/es01/es01.crt ]"]
      interval: 1s
      timeout: 5s
      retries: 120

  es01:
    depends_on:
      setup:
        condition: service_healthy
    image: docker.elastic.co/elasticsearch/elasticsearch:$${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
      - esdata01:/usr/share/elasticsearch/data
    ports:
      - $${ES_PORT}:9200
    environment:
      - node.name=es01
      - cluster.name=$${CLUSTER_NAME}
      - cluster.initial_master_nodes=es01,es02
      - discovery.seed_hosts=es02
      - ELASTIC_PASSWORD=$${ELASTIC_PASSWORD}
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/es01/es01.key
      - xpack.security.http.ssl.certificate=certs/es01/es01.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.http.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/es01/es01.key
      - xpack.security.transport.ssl.certificate=certs/es01/es01.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.license.self_generated.type=$${LICENSE}
    mem_limit: $${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s --cacert config/certs/ca/ca.crt https://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  es02:
    depends_on:
      - es01
    image: docker.elastic.co/elasticsearch/elasticsearch:$${STACK_VERSION}
    volumes:
      - certs:/usr/share/elasticsearch/config/certs
      - esdata02:/usr/share/elasticsearch/data
    environment:
      - node.name=es02
      - cluster.name=$${CLUSTER_NAME}
      - cluster.initial_master_nodes=es01,es02
      - discovery.seed_hosts=es01
      - bootstrap.memory_lock=true
      - xpack.security.enabled=true
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.key=certs/es02/es02.key
      - xpack.security.http.ssl.certificate=certs/es02/es02.crt
      - xpack.security.http.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.http.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.key=certs/es02/es02.key
      - xpack.security.transport.ssl.certificate=certs/es02/es02.crt
      - xpack.security.transport.ssl.certificate_authorities=certs/ca/ca.crt
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.license.self_generated.type=$${LICENSE}
    mem_limit: $${MEM_LIMIT}
    ulimits:
      memlock:
        soft: -1
        hard: -1
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s --cacert config/certs/ca/ca.crt https://localhost:9200 | grep -q 'missing authentication credentials'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120

  kibana:
    depends_on:
      es01:
        condition: service_healthy
      es02:
        condition: service_healthy
    image: docker.elastic.co/kibana/kibana:$${STACK_VERSION}
    volumes:
      - certs:/usr/share/kibana/config/certs
      - kibanadata:/usr/share/kibana/data
    ports:
      - $${KIBANA_PORT}:5601
    environment:
      - SERVERNAME=kibana
      - ELASTICSEARCH_HOSTS=https://es01:9200
      - ELASTICSEARCH_USERNAME=kibana_system
      - ELASTICSEARCH_PASSWORD=$${KIBANA_PASSWORD}
      - ELASTICSEARCH_SSL_CERTIFICATEAUTHORITIES=config/certs/ca/ca.crt
      - SERVER_PUBLICBASEURL=$${KIBANA_URL}
    mem_limit: $${MEM_LIMIT}
    healthcheck:
      test:
        [
          "CMD-SHELL",
          "curl -s -I http://localhost:5601 | grep -q 'HTTP/1.1 302 Found'",
        ]
      interval: 10s
      timeout: 10s
      retries: 120
  logstash:
    build:
      context: ./logstash
    environment:
      LS_JAVA_OPTS: "-Xmx256m -Xms256m"
    volumes:
      - /home/ec2-user/elastic/logstash/logstash.conf:/usr/share/logstash/pipeline/logstash.conf
      - /home/ec2-user/elastic/logstash/logstash.yml:/usr/share/logstash/config/logstash.yml

volumes:
  certs:
    driver: local
  esdata01:
    driver: local
  esdata02:
    driver: local
  kibanadata:
    driver: local
EOF

# Create Logstash configuration
mkdir /home/ec2-user/elastic/logstash
cat << 'EOF' > /home/ec2-user/elastic/logstash/logstash.yml
config:
  reload:
    automatic: true
    interval: 3s
EOF

# Create Logstash pipeline
cat << 'EOF' > /home/ec2-user/elastic/logstash/logstash.conf
input {
  kinesis {
    kinesis_stream_name => "AWS_Logs"
    region => "${REGION}"
    codec => cloudwatch_logs
  }
}

filter {
  if [logGroup] == "elastic/syslog" {
    grok {
      match => { "message" => "%%{SYSLOGBASE}" }
    }
    date {
      timezone => "Etc/UTC"
      match => ["message", "MMM dd HH:mm:ss", "MMM d HH:mm:ss"]
      target => "@timestamp"
    }
    mutate {
      remove_field => [ "messageType", "subscriptionFilters", "timestamp" ]
    }
  }

  if [logGroup] == "elastic/apache-access-log" {
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

  if [logGroup] == "elastic/cloudtrail" {
    json {
      source => "message"
    }
    date {
      timezone => "Etc/UTC"
      match => ["timestamp", "MMM d, yyyy @ HH:mm:ss.SSS", "MMM dd, yyyy @ HH:mm:ss.SSS"]
      target => "@timestamp"
    }
    mutate {
      remove_field => [ "apiVersion", "messageType", "subscriptionFilters" ]
    }
  }
}

output {
  elasticsearch {
     hosts => ["https://es01:9200"]
     index => "awslogs-%%{+YYYY.MM.dd}"
     user => "elastic"
     password => "${PASSWORD}"
     ssl => true
     ssl_certificate_verification => false
   }
}
EOF

# Create Logstash Dockerfile
cat << 'EOF' > /home/ec2-user/elastic/logstash/Dockerfile
FROM docker.elastic.co/logstash/logstash:8.1.3
RUN rm -f /usr/share/logstash/pipeline/logstash.conf && \
  bin/logstash-plugin install logstash-input-kinesis && \
  bin/logstash-plugin install logstash-codec-cloudwatch_logs
EOF

# Adjust permissions
chown -R ec2-user:ec2-user /home/ec2-user

# Start up Elastic
sudo -u ec2-user -i /usr/local/bin/docker-compose -f /home/ec2-user/elastic/docker-compose.yml --env-file /home/ec2-user/elastic/.env up -d
until curl -sku 'elastic:${PASSWORD}' https://localhost:9200/_cat/indices | grep awslogs; do
  sleep 10
done
curl -X POST -u 'elastic:${PASSWORD}' http://localhost:5601/api/saved_objects/index-pattern -d '{"attributes":{"fieldAttrs":"{}","title":"awslogs-*","timeFieldName":"@timestamp","fields":"[]","typeMeta":"{}","runtimeFieldMap":"{}"}}' -H 'kbn-version: 8.1.3' -H 'Content-Type: application/json'