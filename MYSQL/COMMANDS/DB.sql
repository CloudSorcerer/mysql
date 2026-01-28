-- Create new database
CREATE DATABASE app_db;
==============================================================================

-- Remove database schema
DROP DATABASE app_db;
==============================================================================

-- List all databases
SHOW DATABASES;
==============================================================================

-- Create database with charset
CREATE DATABASE app_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
==============================================================================

-- Show database charset
SELECT
SCHEMA_NAME,
DEFAULT_CHARACTER_SET_NAME,
DEFAULT_COLLATION_NAME
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'app_db';
==============================================================================

-- Change default database charset
ALTER DATABASE app_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
==============================================================================

-- Show database size
SELECT
table_schema,
ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS size_gb
FROM information_schema.tables
WHERE table_schema = 'app_db'
GROUP BY table_schema;
==============================================================================

-- Show tables in database
SHOW TABLES FROM app_db;
==============================================================================

-- Check database objects
SELECT
table_name,
engine,
table_rows
FROM information_schema.tables
WHERE table_schema = 'app_db';
==============================================================================
