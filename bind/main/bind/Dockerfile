ARG PERL_VERSION

ARG IMAGE
ARG VERSION

FROM perl:${PERL_VERSION} AS builder

ARG BIND_TYPE
ARG BIND_ZONE
ARG BIND_SECRET

COPY /main/bind/$BIND_TYPE.named.conf /etc/bind/named.tpl.conf

RUN cat /etc/bind/named.tpl.conf | \
    BIND_ZONE="${BIND_ZONE}" \
    BIND_SECRET="${BIND_SECRET}" \
    perl -p \
    -e 's/\Q{{BIND_ZONE}}\E/$ENV{BIND_ZONE}/g;' \
    -e 's/\Q{{BIND_SECRET}}\E/$ENV{BIND_SECRET}/g;' \
    > /etc/bind/named.conf

FROM $IMAGE:$VERSION

COPY --from=builder /etc/bind/named.conf /etc/bind/named.conf

CMD ["named", "-c", "/etc/bind/named.conf", "-g", "-u", "named"]
