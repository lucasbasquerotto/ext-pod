ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

ARG WORDPRESS_INI_FILE_TYPE
ARG ERROR_LOG_FILE

COPY --chown=www-data:www-data /env/wordpress/.env /var/www/html/

RUN mv "$PHP_INI_DIR/php.ini-$WORDPRESS_INI_FILE_TYPE" "$PHP_INI_DIR/php.ini" \
 && echo "error_log = $ERROR_LOG_FILE" >> "$PHP_INI_DIR/php.ini"

