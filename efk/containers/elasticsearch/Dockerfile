ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

RUN bin/elasticsearch-plugin install --batch repository-s3

ARG MAIN_DIR
ARG S3_ACCESS_KEY
ARG S3_SECRET_KEY

COPY $MAIN_DIR/containers/elasticsearch/elasticsearch.yml /usr/share/elasticsearch/config/

RUN if [ -n "$S3_ACCESS_KEY" ]; then \
        echo "$S3_ACCESS_KEY" | bin/elasticsearch-keystore \
        add --stdin --force s3.client.default.access_key; \
    fi; \
    if [ -n "$S3_SECRET_KEY" ]; then \
        echo "$S3_SECRET_KEY" | bin/elasticsearch-keystore \
        add --stdin --force s3.client.default.secret_key; \
    fi
