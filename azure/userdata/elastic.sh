#!/bin/bash

# Install docker and docker-compose
apt update
apt-get install ca-certificates curl gnupg lsb-release -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose -y
usermod -aG docker elastic
systemctl enable docker
systemctl start docker

# Adjust vm.max_map_count
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p

# Create .env file
mkdir /home/elastic/elastic
cat << EOF > /home/elastic/elastic/.env
ELASTIC_PASSWORD=${PASSWORD}
KIBANA_PASSWORD=${PASSWORD}
STACK_VERSION=8.1.3
CLUSTER_NAME=es-cluster
LICENSE=basic
ES_PORT=9200
KIBANA_PORT=5601
MEM_LIMIT=1073741824
KIBANA_URL=http://${URL}
EOF

# Create docker-compose.yml
cat << 'EOF' > /home/elastic/elastic/docker-compose.yml
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
      - /home/elastic/elastic/logstash/logstash.conf:/usr/share/logstash/pipeline/logstash.conf
      - /home/elastic/elastic/logstash/logstash.yml:/usr/share/logstash/config/logstash.yml

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
mkdir /home/elastic/elastic/logstash
cat << 'EOF' > /home/elastic/elastic/logstash/logstash.yml
config:
  reload:
    automatic: true
    interval: 3s
EOF

# Create Logstash pipeline
cat << 'EOF' > /home/elastic/elastic/logstash/logstash.conf
input {
  azure_event_hubs {
      event_hub_connections => ["${CONNSTRING}"]
      threads => 8
      decorate_events => true
      consumer_group => "logstash"
   }
}

filter {
  json {
    source => "message"
  }
  ruby {
    code => "
      if (event.get('records'))
        event.get('records')[0].each {|k, v|
          event.set(k, v);
        }
        event.remove('records');
      end
    "
  }
}

output {
  elasticsearch {
     hosts => ["https://es01:9200"]
     index => "azurelogs-%%{+YYYY.MM.dd}"
     user => "elastic"
     password => "${PASSWORD}"
     ssl => true
     ssl_certificate_verification => false
   }
}
EOF

# Create Logstash Dockerfile
cat << 'EOF' > /home/elastic/elastic/logstash/Dockerfile
FROM docker.elastic.co/logstash/logstash:8.1.3
RUN rm -f /usr/share/logstash/pipeline/logstash.conf && \
  bin/logstash-plugin install logstash-input-azure_event_hubs
EOF

# Adjust permissions
chown -R elastic:elastic /home/elastic

sudo -u elastic -i /usr/bin/docker-compose -f /home/elastic/elastic/docker-compose.yml  --env-file /home/elastic/elastic/.env up -d
until curl -sku 'elastic:${PASSWORD}' https://localhost:9200/_cat/indices | grep azurelogs; do
  sleep 10
done
curl -X POST -u 'elastic:${PASSWORD}' http://localhost:5601/api/saved_objects/index-pattern -d '{"attributes":{"fieldAttrs":"{}","title":"azurelogs-*","timeFieldName":"@timestamp","fields":"[]","typeMeta":"{}","runtimeFieldMap":"{}"}}' -H 'kbn-version: 8.1.3' -H 'Content-Type: application/json'