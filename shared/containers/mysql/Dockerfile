ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY /shared/containers/mysql/mysqld.cnf /etc/mysql/conf.d/mysqld.cnf
COPY /env/mysql/init.sql /docker-entrypoint-initdb.d/

RUN mkdir -p /var/log/mysql \
 && chown -R mysql:mysql /var/log/mysql/ \
 && ls -la /var/log/mysql/
