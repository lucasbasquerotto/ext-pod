ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

ARG BIND_TYPE

COPY /main/bind/$BIND_TYPE.named.conf /etc/bind/named.conf

CMD ["named", "-c", "/etc/bind/named.conf", "-g", "-u", "named"]
