ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

USER root

COPY /main/fluentd/elasticsearch.conf /fluentd/etc/fluent.conf

RUN chmod +rx /fluentd/etc/fluent.conf

USER fluent
