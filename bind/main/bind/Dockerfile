ARG PERL_VERSION

ARG IMAGE
ARG VERSION

FROM perl:${PERL_VERSION} AS builder

ARG BIND_FILE
ARG BIND_TYPE
ARG BIND_ZONE
ARG BIND_SECRET
ARG BIND_MASTER_IP
ARG BIND_SLAVE_IP
ARG BIND_MASTER_NS
ARG BIND_SLAVE_NS
ARG BIND_MASTER_COMMENT_NS
ARG BIND_SLAVE_COMMENT_NS
ARG BIND_EMAIL_HOSTMASTER
ARG BIND_COMMENT_TRANSFER
ARG BIND_COMMENT_MASTERS
ARG BIND_SERIAL

COPY /main/bind/zone.conf /etc/bind/zone.tpl.conf
COPY $BIND_FILE /etc/bind/named.tpl.conf

RUN cat /etc/bind/named.tpl.conf | \
    BIND_TYPE="${BIND_TYPE}" \
    BIND_ZONE="${BIND_ZONE}" \
    BIND_SECRET="${BIND_SECRET}" \
    BIND_MASTER_IP="${BIND_MASTER_IP}" \
    BIND_SLAVE_IP="${BIND_SLAVE_IP}" \
    BIND_COMMENT_TRANSFER="${BIND_COMMENT_TRANSFER}" \
    BIND_COMMENT_MASTERS="${BIND_COMMENT_MASTERS}" \
    perl -p \
    -e 's/\Q{{BIND_TYPE}}\E/$ENV{BIND_TYPE}/g;' \
    -e 's/\Q{{BIND_ZONE}}\E/$ENV{BIND_ZONE}/g;' \
    -e 's/\Q{{BIND_SECRET}}\E/$ENV{BIND_SECRET}/g;' \
    -e 's/\Q{{BIND_MASTER_IP}}\E/$ENV{BIND_MASTER_IP}/g;' \
    -e 's/\Q{{BIND_SLAVE_IP}}\E/$ENV{BIND_SLAVE_IP}/g;' \
    -e 's/\Q{{BIND_COMMENT_TRANSFER}}\E/$ENV{BIND_COMMENT_TRANSFER}/g;' \
    -e 's/\Q{{BIND_COMMENT_MASTERS}}\E/$ENV{BIND_COMMENT_MASTERS}/g;' \
    > /etc/bind/named.conf \
 && cat /etc/bind/zone.tpl.conf | \
    BIND_TYPE="${BIND_TYPE}" \
    BIND_ZONE="${BIND_ZONE}" \
    BIND_MASTER_IP="${BIND_MASTER_IP}" \
    BIND_SLAVE_IP="${BIND_SLAVE_IP}" \
    BIND_MASTER_NS="${BIND_MASTER_NS}" \
    BIND_SLAVE_NS="${BIND_SLAVE_NS}" \
    BIND_MASTER_COMMENT_NS="${BIND_MASTER_COMMENT_NS}" \
    BIND_SLAVE_COMMENT_NS="${BIND_SLAVE_COMMENT_NS}" \
    BIND_EMAIL_HOSTMASTER="${BIND_EMAIL_HOSTMASTER}" \
    BIND_SERIAL="${BIND_SERIAL}" \
    perl -p \
    -e 's/\Q{{BIND_TYPE}}\E/$ENV{BIND_TYPE}/g;' \
    -e 's/\Q{{BIND_ZONE}}\E/$ENV{BIND_ZONE}/g;' \
    -e 's/\Q{{BIND_MASTER_IP}}\E/$ENV{BIND_MASTER_IP}/g;' \
    -e 's/\Q{{BIND_SLAVE_IP}}\E/$ENV{BIND_SLAVE_IP}/g;' \
    -e 's/\Q{{BIND_MASTER_NS}}\E/$ENV{BIND_MASTER_NS}/g;' \
    -e 's/\Q{{BIND_SLAVE_NS}}\E/$ENV{BIND_SLAVE_NS}/g;' \
    -e 's/\Q{{BIND_MASTER_COMMENT_NS}}\E/$ENV{BIND_MASTER_COMMENT_NS}/g;' \
    -e 's/\Q{{BIND_SLAVE_COMMENT_NS}}\E/$ENV{BIND_SLAVE_COMMENT_NS}/g;' \
    -e 's/\Q{{BIND_EMAIL_HOSTMASTER}}\E/$ENV{BIND_EMAIL_HOSTMASTER}/g;' \
    -e 's/\Q{{BIND_SERIAL}}\E/$ENV{BIND_SERIAL}/g;' \
    > /etc/bind/zone.conf

FROM $IMAGE:$VERSION

ARG BIND_TYPE
ARG BIND_ZONE

ENV BIND_TYPE $BIND_TYPE
ENV ZONE_INITIAL_FILE /etc/bind/zone.conf
ENV ZONE_FINAL_FILE /var/main/data/bind/${BIND_TYPE}/${BIND_ZONE}

COPY --from=builder /etc/bind/named.conf /etc/bind/named.conf
COPY --from=builder /etc/bind/zone.conf $ZONE_INITIAL_FILE
COPY /main/bind/docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["named", "-c", "/etc/bind/named.conf", "-g", "-u", "named"]
