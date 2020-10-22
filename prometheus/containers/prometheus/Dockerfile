ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

ARG MAIN_DIR

COPY $MAIN_DIR/containers/prometheus/prometheus.yml /etc/prometheus/

RUN chown 65534:65534 /prometheus