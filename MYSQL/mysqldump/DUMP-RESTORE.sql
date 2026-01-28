-- ✅ Tables (structure + data) (no views, no triggers, no routines, no events)

mysqldump -u root -p db_alpha \
$(mysql -N -e "
  SELECT CONCAT('--ignore-table=db_alpha.', TABLE_NAME)
  FROM information_schema.VIEWS
  WHERE TABLE_SCHEMA='db_alpha';
") \
--skip-triggers --skip-events --skip-routines \
> /backup/db_alpha_tables_only.sql

=====================================================================================================
-- ✅ Table STRUCTURE ONLY (no views, no triggers, no routines, no events)

mysqldump -u root -p db_alpha \
--no-data \
$(mysql -N -e "
  SELECT CONCAT('--ignore-table=db_alpha.', TABLE_NAME)
  FROM information_schema.VIEWS
  WHERE TABLE_SCHEMA='db_alpha';
") \
--skip-triggers --skip-events --skip-routines \
> /backup/db_alpha_tables_structure_only.sql

=====================================================================================================
-- ✅ VIEWS ONLY  1 DB

mysqldump -u root -p db_alpha \
--no-data \
$(mysql -N -e "
  SELECT CONCAT('--ignore-table=db_alpha.', TABLE_NAME)
  FROM information_schema.TABLES
  WHERE TABLE_SCHEMA='db_alpha'
    AND TABLE_TYPE='BASE TABLE';
") \
--skip-triggers --skip-events --skip-routines \
> /backup/db_alpha_views_only.sql

=====================================================================================================

-- ✅ TRIGGERS ONLY  1 DB

mysqldump -u root -p db_alpha \
--no-data --no-create-info \
--triggers --skip-events --skip-routines \
> /backup/db_alpha_triggers_only.sql

=====================================================================================================

-- ✅ EVENTS ONLY  1 DB
mysqldump -u root -p db_alpha \
--events --no-data --no-create-info \
--skip-triggers --skip-routines \
> /backup/db_alpha_events_only.sql

=====================================================================================================

-- ✅ Routines ONLY  1 DB
mysqldump -u root -p db_alpha \
--routines --no-data --no-create-info \
--skip-triggers --skip-events \
> /backup/db_alpha_routines_only.sql

=====================================================================================================
########################################## RESTORE ##################################################

-- ✅ Minimal restore order (remember this)

DB → tables structure → data → views → routines → triggers → events

=====================================================================================================

-- DROP database (start clean)

mysql -u root -p -e "DROP DATABASE IF EXISTS db_alpha;"
=====================================================================================================

2-- ️Create database (if not exists)

mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS db_alpha;"
=====================================================================================================

-- Restore according restore order
mysql -u root -p db_alpha < /backup/backup_fule_name.sql