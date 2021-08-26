ARG IMAGE

FROM $IMAGE

ARG MAIN_DIR

COPY $MAIN_DIR/containers/grafana/provisioning/ /etc/grafana/provisioning/

COPY --chown=grafana:grafana /env/grafana/datasource.yml /etc/grafana/provisioning/datasources/default.yml