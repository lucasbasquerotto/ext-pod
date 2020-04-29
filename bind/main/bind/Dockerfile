FROM alpine:latest

RUN apk --update add bind

ARG BIND_TYPE

COPY /main/bind/$BIND_TYPE.named.conf /etc/bind/named.conf

CMD ["named", "-c", "/etc/bind/named.conf", "-g", "-u", "named"]
