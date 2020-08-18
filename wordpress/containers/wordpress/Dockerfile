ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

ARG WORDPRESS_INI_FILE_TYPE

COPY --chown=www-data:www-data /env/wordpress/.env /var/www/html/

RUN mv "$PHP_INI_DIR/php.ini-$WORDPRESS_INI_FILE_TYPE" "$PHP_INI_DIR/php.ini"

COPY --chown=www-data:www-data /wordpress/containers/wordpress/plugins/w3tc/app/w3tc-config/ /var/www/html/web/app/w3tc-config/
COPY --chown=www-data:www-data /wordpress/containers/wordpress/plugins/w3tc/app/advanced-cache.php /var/www/html/web/app/
COPY --chown=www-data:www-data /wordpress/containers/wordpress/plugins/w3tc/app/object-cache.php /var/www/html/web/app/
COPY --chown=www-data:www-data /wordpress/containers/wordpress/plugins/w3tc/.htaccess /var/www/html/web/

