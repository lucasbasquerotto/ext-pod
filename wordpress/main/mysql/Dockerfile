ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY mysqld.cnf /etc/mysql/conf.d/mysqld.cnf

RUN mkdir -p /var/log/mysql \
 && chown -R mysql:mysql /var/log/mysql/ \
 && ls -la /var/log/mysql/
