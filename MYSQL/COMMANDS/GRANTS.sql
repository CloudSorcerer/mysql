#### GRANTS FOR Views, routines, procedures, events, triggers ####

=====================================================================
-- Allow view creation
GRANT CREATE VIEW ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Allow trigger creation
GRANT TRIGGER ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Allow procedure function creation
GRANT CREATE ROUTINE ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Allow routine modification
GRANT ALTER ROUTINE ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Allow routine execution
GRANT EXECUTE ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Allow event creation
GRANT EVENT ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Revoke view creation
REVOKE CREATE VIEW ON app_db.* FROM 'app_user'@'%';


=====================================================================
-- Revoke trigger creation
REVOKE TRIGGER ON app_db.* FROM 'app_user'@'%';


=====================================================================
-- Revoke routine creation
REVOKE CREATE ROUTINE ON app_db.* FROM 'app_user'@'%';


=====================================================================
-- Revoke routine execution
REVOKE EXECUTE ON app_db.* FROM 'app_user'@'%';


=====================================================================
-- Revoke event creation
REVOKE EVENT ON app_db.* FROM 'app_user'@'%';


=====================================================================
-- Show user database grants
SHOW GRANTS FOR 'app_user'@'%';



-- Check definers in database
SELECT
routine_name,
definer
FROM information_schema.routines
WHERE routine_schema = 'app_db';


=====================================================================
-- List database events
SHOW EVENTS FROM app_db;


######## DATABASE-LEVEL GRANTS #########

=====================================================================
-- Full database access
GRANT ALL PRIVILEGES ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Read only database access
GRANT SELECT ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Standard read write access
GRANT SELECT, INSERT, UPDATE, DELETE ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Grant database usage only
GRANT USAGE ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Revoke all database privileges
REVOKE ALL PRIVILEGES ON app_db.* FROM 'app_user'@'%';


######### TABLE-LEVEL GRANTS ##########

=====================================================================
-- Full table access
GRANT ALL PRIVILEGES ON app_db.products TO 'app_user'@'%';


=====================================================================
-- Read only table access
GRANT SELECT ON app_db.products TO 'app_user'@'%';


=====================================================================
-- Modify table data
GRANT INSERT, UPDATE, DELETE ON app_db.products TO 'app_user'@'%';


=====================================================================
-- Lock tables privilege at database level
GRANT LOCK TABLES ON app_db.* TO 'app_user'@'%';


=====================================================================
-- Revoke table privileges
REVOKE ALL PRIVILEGES ON app_db.products FROM 'app_user'@'%';


=====================================================================
-- Check table privileges
SELECT *
FROM information_schema.table_privileges
WHERE table_schema = 'app_db'
AND grantee LIKE "'app_user'%";
