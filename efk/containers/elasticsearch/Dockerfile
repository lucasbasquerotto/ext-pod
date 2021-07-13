ARG IMAGE

FROM $IMAGE

RUN bin/elasticsearch-plugin install --batch repository-s3

COPY /env/elasticsearch/elasticsearch.yml /usr/share/elasticsearch/config/
