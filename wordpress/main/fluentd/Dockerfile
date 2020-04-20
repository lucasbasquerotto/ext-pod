ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

USER root

ARG OUTPUT_PLUGIN

COPY /main/fluentd/${OUTPUT_PLUGIN}.conf /fluentd/etc/fluent.conf

RUN chmod +rx /fluentd/etc/fluent.conf

USER fluent
