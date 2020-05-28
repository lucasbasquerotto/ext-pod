ARG IMAGE
ARG VERSION

FROM $IMAGE:$VERSION

COPY /main/mediawiki/CustomCliInstaller.php /var/www/html/includes/installer/CustomCliInstaller.php
COPY /main/mediawiki/upgrade.php /var/www/html/maintenance/upgrade.php
COPY /env/mediawiki/LocalSettings.php /var/www/html/LocalSettings.php