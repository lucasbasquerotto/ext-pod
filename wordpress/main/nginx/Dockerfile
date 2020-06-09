ARG PERL_VERSION

ARG IMAGE
ARG VERSION

FROM perl:${PERL_VERSION} AS builder

COPY /main/nginx/ /tmp/tpl/

ARG MAIN_DOMAIN
ARG MAIN_DOMAIN_PORT
ARG MAIN_DOMAIN_PORT_SUFFIX
ARG MAIN_PROTOCOL
ARG MAIN_LISTEN
ARG MAIN_LISTEN_REDIRECT
ARG MAIN_NON_SSL_COMMENT
ARG PMA_DOMAIN
ARG PMA_DOMAIN_PORT
ARG PMA_DOMAIN_PORT_SUFFIX
ARG PMA_PROTOCOL
ARG PMA_LISTEN
ARG PMA_LISTEN_REDIRECT
ARG PMA_NON_SSL_COMMENT

RUN mkdir -p /tmp/main/ \
 && cat /tmp/tpl/nginx.conf | \
    MAIN_DOMAIN="${MAIN_DOMAIN}" \
    MAIN_DOMAIN_PORT="${MAIN_DOMAIN_PORT}" \
    MAIN_DOMAIN_PORT_SUFFIX="${MAIN_DOMAIN_PORT_SUFFIX}" \
    MAIN_PROTOCOL="${MAIN_PROTOCOL}" \
    MAIN_LISTEN="${MAIN_LISTEN}" \
    MAIN_LISTEN_REDIRECT="${MAIN_LISTEN_REDIRECT}" \
    MAIN_CERTIFICATE_DIRECTIVE="${MAIN_CERTIFICATE_DIRECTIVE}" \
    MAIN_CERTIFICATE_KEY_DIRECTIVE="${MAIN_CERTIFICATE_KEY_DIRECTIVE}" \
    PMA_DOMAIN="${PMA_DOMAIN}" \
    PMA_DOMAIN_PORT="${PMA_DOMAIN_PORT}" \
    PMA_DOMAIN_PORT_SUFFIX="${PMA_DOMAIN_PORT_SUFFIX}" \
    PMA_PROTOCOL="${PMA_PROTOCOL}" \
    PMA_LISTEN="${PMA_LISTEN}" \
    PMA_LISTEN_REDIRECT="${PMA_LISTEN_REDIRECT}" \
    PMA_CERTIFICATE_DIRECTIVE="${PMA_CERTIFICATE_DIRECTIVE}" \
    PMA_CERTIFICATE_KEY_DIRECTIVE="${PMA_CERTIFICATE_KEY_DIRECTIVE}" \
    perl -p \
    -e 's/\Q{{MAIN_DOMAIN}}\E/$ENV{MAIN_DOMAIN}/g;' \
    -e 's/\Q{{MAIN_DOMAIN_PORT}}\E/$ENV{MAIN_DOMAIN_PORT}/g;' \
    -e 's/\Q{{MAIN_DOMAIN_PORT_SUFFIX}}\E/$ENV{MAIN_DOMAIN_PORT_SUFFIX}/g;' \
    -e 's/\Q{{MAIN_PROTOCOL}}\E/$ENV{MAIN_PROTOCOL}/g;' \
    -e 's/\Q{{MAIN_LISTEN}}\E/$ENV{MAIN_LISTEN}/g;' \
    -e 's/\Q{{MAIN_LISTEN_REDIRECT}}\E/$ENV{MAIN_LISTEN_REDIRECT}/g;' \
    -e 's/\Q{{MAIN_NON_SSL_COMMENT}}\E/$ENV{MAIN_NON_SSL_COMMENT}/g;' \
    -e 's/\Q{{PMA_DOMAIN}}\E/$ENV{PMA_DOMAIN}/g;' \
    -e 's/\Q{{PMA_DOMAIN_PORT}}\E/$ENV{PMA_DOMAIN_PORT}/g;' \
    -e 's/\Q{{PMA_DOMAIN_PORT_SUFFIX}}\E/$ENV{PMA_DOMAIN_PORT_SUFFIX}/g;' \
    -e 's/\Q{{PMA_PROTOCOL}}\E/$ENV{PMA_PROTOCOL}/g;' \
    -e 's/\Q{{PMA_LISTEN}}\E/$ENV{PMA_LISTEN}/g;' \
    -e 's/\Q{{PMA_LISTEN_REDIRECT}}\E/$ENV{PMA_LISTEN_REDIRECT}/g;' \
    -e 's/\Q{{PMA_NON_SSL_COMMENT}}\E/$ENV{PMA_NON_SSL_COMMENT}/g;' \
    > /tmp/main/nginx.conf \
 && cat /tmp/tpl/include/ssl.conf | \
    DOMAIN="${MAIN_DOMAIN}" \
    perl -p \
    -e 's/\Q{{DOMAIN}}\E/$ENV{DOMAIN}/g;' \
    > /tmp/main/main.ssl.conf \
 && cat /tmp/tpl/include/ssl.conf | \
    DOMAIN="${PMA_DOMAIN}" \
    perl -p \
    -e 's/\Q{{DOMAIN}}\E/$ENV{DOMAIN}/g;' \
    > /tmp/main/pma.ssl.conf \
 && mv /tmp/tpl/include/gzip.conf /tmp/main/ \
 && mv /tmp/tpl/include/options-ssl-nginx.conf /tmp/main/ \
 && mv /tmp/tpl/include/ssl-dhparams.pem /tmp/main/ \
 && mv /tmp/tpl/include/ssl.conf /tmp/main/

FROM $IMAGE:$VERSION

COPY --from=builder /tmp/main/ /etc/nginx/
