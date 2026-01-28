-- Create new table
CREATE TABLE app_db.products (
  id INT PRIMARY KEY,
  name VARCHAR(100)
);
===========================================================================

-- Remove table data
DROP TABLE app_db.products;
===========================================================================

-- Show table row count
SELECT COUNT(*) FROM slap.t;
===========================================================================

-- Show table size
SELECT
table_name,
ROUND((data_length + index_length) / 1024 / 1024, 2) AS size_mb
FROM information_schema.tables
WHERE table_schema = 'db'
AND table_name = 'table';
===========================================================================

-- Show table engine
SHOW TABLE STATUS FROM app_db LIKE 'products';
===========================================================================

