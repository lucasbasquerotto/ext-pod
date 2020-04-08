ARG IMAGE
ARG VERSION

FROM perl:${PERL_VERSION} AS builder

COPY /main/fluentd/ /tmp/tpl/

ARG ELASTICSEARCH_PORT
ARG FLUSH_INTERVAL

RUN cat /tmp/tpl/elasticsearch.conf | \
    ELASTICSEARCH_PORT="${ELASTICSEARCH_PORT}" \
    FLUSH_INTERVAL="${FLUSH_INTERVAL}" \
    perl -p \
    -e 's/\Q{{ELASTICSEARCH_PORT}}\E/$ENV{ELASTICSEARCH_PORT}/g;' \
    -e 's/\Q{{FLUSH_INTERVAL}}\E/$ENV{FLUSH_INTERVAL}/g;' \
    > /fluentd.conf

FROM $IMAGE:$VERSION

USER root

COPY --from=builder /fluentd.conf /fluentd/etc/fluentd.conf

RUN chmod +rx /fluentd/etc/fluent.conf

USER fluent
