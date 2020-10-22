ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

ARG MAIN_DIR

COPY $MAIN_DIR/containers/mediawiki/CustomCliInstaller.php /var/www/html/includes/installer/CustomCliInstaller.php
COPY $MAIN_DIR/containers/mediawiki/upgrade.php /var/www/html/maintenance/upgrade.php
COPY /env/mediawiki/LocalSettings.php /var/www/html/LocalSettings.php