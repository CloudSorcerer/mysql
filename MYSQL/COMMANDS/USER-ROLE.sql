=================================================================
-- Create new MySQL user
CREATE USER 'app_user'@'%' IDENTIFIED BY 'StrongPass!';

=================================================================
-- Change user password
ALTER USER 'app_user'@'%' IDENTIFIED BY 'NewStrongPass!';

=================================================================
-- Remove user account
DROP USER 'app_user'@'%';

-- Create reusable role
CREATE ROLE 'app_readonly';

=================================================================
-- Remove role definition
DROP ROLE 'app_readonly';

=================================================================
-- Assign role to user
GRANT 'app_readonly' TO 'app_user'@'%';

=================================================================
-- Enable role by default
SET DEFAULT ROLE ALL TO 'app_user'@'%';

=================================================================
-- Show user grants
SHOW GRANTS FOR 'app_user'@'%';

=================================================================
-- Show role privileges
SHOW GRANTS FOR 'app_readonly';

=================================================================
-- Show user authentication plugin
SELECT user, host, plugin
FROM mysql.user
WHERE user = 'app_user';

=================================================================
-- Check account lock status
SELECT user, host, account_locked
FROM mysql.user
WHERE user = 'app_user';

=================================================================
-- Lock or unlock user
ALTER USER 'app_user'@'%' ACCOUNT LOCK;

=================================================================
-- Unlock user account
ALTER USER 'app_user'@'%' ACCOUNT UNLOCK;

=================================================================
-- Show all users & hosts
SELECT user, host FROM mysql.user;

=================================================================
-- Show login user (who connected)
SELECT USER();

=================================================================
-- Show current effective user (privileges used)
SELECT CURRENT_USER();

=================================================================
-- Show both together (best practice)
SELECT USER() AS login_user, CURRENT_USER() AS effective_user;