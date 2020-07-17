ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY /shared/containers/nginx/include/ /etc/nginx/include/
COPY /env/nginx/conf/.htpasswd /etc/nginx/conf/
COPY /env/nginx/nginx.conf /etc/nginx/
