### Routines


--  SHOW ROUTINES for ONE database
SELECT
  DEFINER,
  ROUTINE_TYPE,
  ROUTINE_SCHEMA,
  ROUTINE_NAME AS routine_name,
  CREATED
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'app_db'
ORDER BY ROUTINE_TYPE, ROUTINE_NAME;
=============================================================================


-- SHOW ALL ROUTINES
SELECT
  DEFINER,
  ROUTINE_TYPE,
  ROUTINE_SCHEMA,
  ROUTINE_NAME AS routine_name,
  CREATED
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA NOT IN (
    'mysql',
    'sys',
    'information_schema',
    'performance_schema'
);

=============================================================================

### Stored procedure


-- Create stored procedure
DELIMITER $$

CREATE PROCEDURE app_db.add_product(IN p_name VARCHAR(100))
BEGIN
  INSERT INTO app_db.products(name)
  VALUES (p_name);
END$$

DELIMITER ;
=============================================================================


-- Call and check
CALL app_db.add_product('Apple');
CALL app_db.add_product('Banana');

SELECT * FROM app_db.products;
=============================================================================


-- SHOW  Procedures for ONE database
SELECT
  DEFINER,
  ROUTINE_TYPE,
  ROUTINE_SCHEMA,
  ROUTINE_NAME AS procedure_name,
  CREATED
FROM information_schema.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_SCHEMA = 'app_db'
ORDER BY ROUTINE_NAME;
=============================================================================


-- SHOW ALL Procedures
SELECT
  DEFINER,
  ROUTINE_TYPE,
  ROUTINE_SCHEMA,
  ROUTINE_NAME AS procedure_name,
  CREATED
FROM information_schema.ROUTINES
WHERE ROUTINE_TYPE = 'PROCEDURE'
  AND ROUTINE_SCHEMA NOT IN (
    'mysql',
    'sys',
    'information_schema',
    'performance_schema'
  );
=============================================================================

### Functions


-- Create function
DELIMITER $$

CREATE FUNCTION app_db.get_product_count()
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE cnt INT DEFAULT 0;
  SELECT COUNT(*) INTO cnt FROM app_db.products;
  RETURN cnt;
END$$

DELIMITER ;
=============================================================================


-- Show ALL functions (only user created)
SELECT
  DEFINER,
  ROUTINE_TYPE,
  ROUTINE_SCHEMA,
  ROUTINE_NAME AS function_name,
  CREATED
FROM information_schema.ROUTINES
WHERE ROUTINE_TYPE = 'FUNCTION'
  AND ROUTINE_SCHEMA NOT IN (
    'mysql',
    'sys',
    'information_schema',
    'performance_schema'
  );
=============================================================================


-- Show functions (only user created) for 1 DB
SELECT
  DEFINER,
  ROUTINE_TYPE,
  ROUTINE_SCHEMA = 'database',
  ROUTINE_NAME AS function_name,
  CREATED
FROM information_schema.ROUTINES
WHERE ROUTINE_TYPE = 'FUNCTION'
  AND ROUTINE_SCHEMA NOT IN (
    'mysql',
    'sys',
    'information_schema',
    'performance_schema'
  );
=============================================================================


-- Call function
SELECT databse.function_name(arg1, arg2) AS any_name_for_result;
=============================================================================