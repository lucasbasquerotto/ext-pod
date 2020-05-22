ARG PERL_VERSION

ARG IMAGE
ARG VERSION

FROM perl:${PERL_VERSION} AS builder

COPY /main/nginx/ /tmp/tpl/

ARG MAIN_DOMAIN
ARG MAIN_DOMAIN_PORT
ARG MAIN_DOMAIN_PORT_SUFFIX

RUN cat /tmp/tpl/nginx.conf | \
    MAIN_DOMAIN="${MAIN_DOMAIN}" \
    MAIN_DOMAIN_PORT="${MAIN_DOMAIN_PORT}" \
    MAIN_DOMAIN_PORT_SUFFIX="${MAIN_DOMAIN_PORT_SUFFIX}" \
    perl -p \
    -e 's/\Q{{MAIN_DOMAIN}}\E/$ENV{MAIN_DOMAIN}/g;' \
    -e 's/\Q{{MAIN_DOMAIN_PORT}}\E/$ENV{MAIN_DOMAIN_PORT}/g;' \
    -e 's/\Q{{MAIN_DOMAIN_PORT_SUFFIX}}\E/$ENV{MAIN_DOMAIN_PORT_SUFFIX}/g;' \
    > /nginx.conf

FROM $IMAGE:$VERSION

COPY --from=builder /nginx.conf /etc/nginx/nginx.conf
