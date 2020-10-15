ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY /prometheus/containers/prometheus/prometheus.yml /etc/prometheus/

RUN chown 65534:65534 /prometheus