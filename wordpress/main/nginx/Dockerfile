ARG PERL_VERSION

ARG IMAGE
ARG VERSION

FROM perl:${PERL_VERSION} AS builder

COPY /main/nginx/ /tmp/tpl/

ARG MAIN_DOMAIN
ARG MAIN_DOMAIN_PORT
ARG PMA_DOMAIN
ARG PMA_DOMAIN_PORT

RUN mkdir /aws \
 && cat /tmp/tpl/config.user.inc | \
    MAIN_DOMAIN="${MAIN_DOMAIN}" \
    MAIN_DOMAIN_PORT="${MAIN_DOMAIN_PORT}" \
    PMA_DOMAIN="${PMA_DOMAIN}" \
    PMA_DOMAIN_PORT="${PMA_DOMAIN_PORT}" \
    perl -p \
    -e 's/\Q{{MAIN_DOMAIN}}\E/$ENV{MAIN_DOMAIN}/g;' \
    -e 's/\Q{{MAIN_DOMAIN_PORT}}\E/$ENV{MAIN_DOMAIN_PORT}/g;' \
    -e 's/\Q{{PMA_DOMAIN}}\E/$ENV{PMA_DOMAIN}/g;' \
    -e 's/\Q{{PMA_DOMAIN_PORT}}\E/$ENV{PMA_DOMAIN_PORT}/g;' \
    > /config.user.inc

FROM $IMAGE:$VERSION

COPY --from=builder /nginx.conf /etc/nginx/nginx.conf
