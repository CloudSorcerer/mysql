########################################## WAR ROOM ##########################################


################# Threads & Processlist #################


-- Map thread to process
SELECT processlist_id
FROM   performance_schema.threads
WHERE  thread_id = XXXXXXX; 



-- Long running active queries
SELECT *
FROM INFORMATION_SCHEMA.PROCESSLIST
WHERE TIME > 60
AND STATE NOT LIKE 'Waiting%'\G



-- Long non-idle queries
SELECT *
FROM INFORMATION_SCHEMA.PROCESSLIST
WHERE TIME > 60
AND STATE NOT LIKE 'Waiting%'
AND STATE NOT LIKE 'Sleep'
AND COMMAND != 'Sleep'\G



-- Sessions grouped by state
SELECT state, COUNT(*) AS count
FROM information_schema.processlist
GROUP BY state;



-- Connections per user
SELECT user, COUNT(*) AS count
FROM information_schema.processlist
GROUP BY user;


##################### Connections & Limits #####################

-- Current active connections
SHOW STATUS LIKE 'Threads_connected';



-- Peak connection usage
SHOW STATUS LIKE 'Max_used_connections';



-- Max allowed connections
SHOW VARIABLES LIKE 'max_connections';



-- Idle connection timeout
SHOW VARIABLES LIKE 'wait_timeout';


##################### Table & Database Size #####################


-- Single table size
SELECT table_name AS `Table`,
ROUND(((data_length + index_length) / 1024 / 1024 / 1024), 2) `Size in GB`
FROM information_schema.TABLES
WHERE table_schema = "XXXXXXXXXX"
AND table_name = "XXXXXXXXXX";



-- Database sizes summary
SELECT table_schema AS "Database",
ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS "Size (GB)"
FROM information_schema.TABLES
GROUP BY table_schema;



-- Total MySQL data size
SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2) AS "Total Size (GB)"
FROM information_schema.TABLES;


#####################  Locks & Deadlocks ###################


-- Show Lock
 SELECT * FROM information_schema.innodb_locks;


-- Deadlock counter
SELECT *
FROM INFORMATION_SCHEMA.INNODB_METRICS
WHERE NAME LIKE 'lock_deadlocks'\G



-- Failed connection attempts
SHOW GLOBAL STATUS LIKE 'Aborted_connects';



-- Too many connections errors
SHOW GLOBAL STATUS LIKE 'Connection_errors_max_connections';



-- Internal connection failures
SHOW GLOBAL STATUS LIKE 'Connection_errors_internal';



-- Blocking vs waiting transactions (Who block whom)
SELECT r.trx_id waiting_trx_id,
r.trx_mysql_thread_id waiting_thread,
r.trx_query waiting_query,
b.trx_id blocking_trx_id,
b.trx_mysql_thread_id blocking_thread,
b.trx_query blocking_query
FROM performance_schema.data_lock_waits w
INNER JOIN information_schema.innodb_trx b
ON b.trx_id = w.blocking_engine_transaction_id
INNER JOIN information_schema.innodb_trx r
ON r.trx_id = w.requesting_engine_transaction_id;



-- Which box is locked and how - Which row/index/table is locked and why?
SELECT
w.THREAD_ID AS waiting_thread,
w.OBJECT_SCHEMA,
w.OBJECT_NAME,
w.INDEX_NAME,
w.LOCK_TYPE,
w.LOCK_MODE AS waiting_lock_mode,
b.THREAD_ID AS blocking_thread,
b.LOCK_MODE AS blocking_lock_mode,
t.PROCESSLIST_USER AS blocking_user,
t.PROCESSLIST_COMMAND AS blocking_command,
t.PROCESSLIST_TIME AS blocking_time,
t.PROCESSLIST_INFO  AS blocking_query
FROM performance_schema.data_lock_waits dw
JOIN performance_schema.data_locks w ON dw.REQUESTING_ENGINE_LOCK_ID = w.ENGINE_LOCK_ID
JOIN performance_schema.data_locks b ON dw.BLOCKING_ENGINE_LOCK_ID  = b.ENGINE_LOCK_ID
LEFT JOIN performance_schema.threads t ON b.THREAD_ID = t.THREAD_ID
ORDER BY blocking_time DESC;



-- Generate table check commands
SELECT CONCAT('CHECK TABLE ', table_schema, '.', table_name, ';')
FROM information_schema.tables
WHERE table_schema = 'your_database';


################# Charset & Collation ######################


-- Database charset info
SELECT
SCHEMA_NAME AS db_name,
DEFAULT_CHARACTER_SET_NAME AS charset,
DEFAULT_COLLATION_NAME AS collation
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'your_database_name';



-- Change database charset
ALTER DATABASE your_database_name
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;



-- Show Lock
 SELECT * FROM information_schema.innodb_locks;



 -- Show innodb buffer pool
 show variables like 'innodb_buffer_pool_size';

-- Show innodb buffer pool MB - GB
 SELECT
  variable_value                                     AS bytes,
  ROUND(variable_value / 1024 / 1024, 2)             AS MB,
  ROUND(variable_value / 1024 / 1024 / 1024, 2)      AS GB
FROM performance_schema.global_variables
WHERE variable_name = 'innodb_buffer_pool_size';



-- innodb engine status - checking DEADLOCK
 SHOW ENGINE INNODB STATUS\G



-- who is holding the lock, for how long,
 SELECT
  r.trx_id                AS waiting_trx_id,
  r.trx_mysql_thread_id   AS waiting_thread,
  TIMESTAMPDIFF(SECOND, r.trx_started, NOW()) AS waiting_time_sec,
  r.trx_query             AS waiting_query,
 
  b.trx_id                AS blocking_trx_id,
  b.trx_mysql_thread_id   AS blocking_thread,
  TIMESTAMPDIFF(SECOND, b.trx_started, NOW()) AS blocking_time_sec,
  b.trx_query             AS blocking_query
FROM information_schema.innodb_lock_waits w
JOIN information_schema.innodb_trx r
  ON r.trx_id = w.requesting_trx_id
JOIN information_schema.innodb_trx b
  ON b.trx_id = w.blocking_trx_id;



-- Summary about max connections
SELECT
  SUM(p.COMMAND='Sleep') AS sleeping,
  SUM(p.COMMAND!='Sleep') AS active,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status    WHERE VARIABLE_NAME='Threads_connected')    AS threads_connected_now,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_status    WHERE VARIABLE_NAME='Max_used_connections') AS max_used_connections,
  (SELECT VARIABLE_VALUE FROM performance_schema.global_variables WHERE VARIABLE_NAME='max_connections')     AS max_connections
FROM information_schema.PROCESSLIST p;

