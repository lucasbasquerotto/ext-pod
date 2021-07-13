ARG IMAGE

FROM $IMAGE

ARG ENV

COPY --chown=node:node /env/ghost/config.json /var/lib/ghost/config.${ENV}.json
