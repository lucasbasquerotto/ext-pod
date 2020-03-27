ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

ARG WORDPRESS_ENV

COPY --chown=www-data:www-data /env/wordpress/.env /var/www/html/

RUN mv "$PHP_INI_DIR/php.ini-$WORDPRESS_ENV" "$PHP_INI_DIR/php.ini" 
