ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

USER root

ARG OUTPUT_PLUGIN

COPY /main/fluentd/${OUTPUT_PLUGIN}.conf /fluentd/etc/fluent.conf

RUN mkdir -p /var/log/main \
 && chown fluent /var/log/main \
 && chmod +rx /fluentd/etc/fluent.conf

USER fluent
