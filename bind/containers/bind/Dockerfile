ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY /env/bind/named.conf /etc/bind/named.conf

CMD ["named", "-c", "/etc/bind/named.conf", "-g", "-u", "named"]
