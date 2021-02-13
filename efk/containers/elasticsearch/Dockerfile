ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

RUN bin/elasticsearch-plugin install --batch repository-s3

ARG MAIN_DIR
ARG S3_ENDPOINT
ARG S3_ACCESS_KEY
ARG S3_SECRET_KEY

COPY $MAIN_DIR/containers/elasticsearch/elasticsearch.yml /usr/share/elasticsearch/config/

RUN echo "" >> /usr/share/elasticsearch/config/elasticsearch.yml; \
    if [ -n "$S3_ENDPOINT" ]; then \
        echo "s3.client.default.endpoint: $S3_ENDPOINT" \
            >> /usr/share/elasticsearch/config/elasticsearch.yml; \
    fi; \
    if [ -n "$S3_ACCESS_KEY" ]; then \
        echo "$S3_ACCESS_KEY" | bin/elasticsearch-keystore \
            add --stdin --force s3.client.default.access_key; \
    fi; \
    if [ -n "$S3_SECRET_KEY" ]; then \
        echo "$S3_SECRET_KEY" | bin/elasticsearch-keystore \
            add --stdin --force s3.client.default.secret_key; \
    fi
