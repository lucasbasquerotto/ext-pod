CREATE USER IF NOT EXISTS 'viewer'@'%' IDENTIFIED BY '{{ params.viewer_password }}';
GRANT SELECT, SHOW VIEW, PROCESS, REPLICATION CLIENT, CREATE TEMPORARY TABLES ON *.* TO 'viewer'@'%';

CREATE USER IF NOT EXISTS '{{ params.db_user }}'@'%' IDENTIFIED BY '{{ params.db_password }}';
GRANT ALL PRIVILEGES ON `{{ params.db_name }}`.* TO '{{ params.db_user }}'@'%';
