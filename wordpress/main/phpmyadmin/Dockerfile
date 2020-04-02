ARG PERL_VERSION

ARG IMAGE
ARG VERSION

FROM perl:${PERL_VERSION} AS builder

COPY /main/phpmyadmin/ /tmp/tpl/

ARG LOGIN_COOKIE_VALIDITY

RUN cat /tmp/tpl/config.user.inc.php | \
    LOGIN_COOKIE_VALIDITY="${LOGIN_COOKIE_VALIDITY}" \
    perl -p \
    -e 's/\Q{{LOGIN_COOKIE_VALIDITY}}\E/$ENV{LOGIN_COOKIE_VALIDITY}/g;' \
    > /config.user.inc.php

FROM $IMAGE:$VERSION

COPY --from=builder /config.user.inc.php /etc/phpmyadmin/config.user.inc.php
