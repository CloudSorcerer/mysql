
-- Create simple view
CREATE VIEW db_name.view_name AS
SELECT *
FROM db_name.table_name;
-- Saves select query
=============================================================


-- Query view data
SELECT * FROM db_name.view_name;
-- Reads virtual table
=============================================================


-- List views in 1 db
SELECT
  TABLE_SCHEMA,
  TABLE_NAME AS view_name,
  DEFINER,
  'VIEW' AS OBJECT_TYPE,
  SECURITY_TYPE,
  IS_UPDATABLE
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'db_name';
-- Shows database views
=============================================================


-- List all DB's views
SELECT
  TABLE_SCHEMA,
  TABLE_NAME AS view_name,
  'VIEW' AS OBJECT_TYPE,
  DEFINER,
  SECURITY_TYPE,
  IS_UPDATABLE
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA NOT IN (
  'mysql',
  'sys',
  'information_schema',
  'performance_schema'
)
ORDER BY TABLE_SCHEMA, view_name;
-- Excludes system views
=============================================================


-- Show view SQL
SHOW CREATE VIEW db_name.view_name;
-- Displays view definition
=============================================================


-- Remove view
DROP VIEW db_name.view_name;
-- Deletes view
=============================================================


-- Remove all view for 1 DB
SET SESSION group_concat_max_len = 1000000;

SELECT GROUP_CONCAT(
  CONCAT('`', TABLE_SCHEMA, '`.`', TABLE_NAME, '`')
  SEPARATOR ', '
) INTO @views
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'db_alpha';

SET @sql = CONCAT('DROP VIEW IF EXISTS ', @views);

SELECT @sql;   -- optional check

PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

=============================================================