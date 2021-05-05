ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

ARG ENV

COPY /env/ghost/config.json /var/lib/ghost/config.${ENV}.json
