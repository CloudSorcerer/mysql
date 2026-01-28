
-- Create EVENT with DEFINER (example)
SET GLOBAL event_scheduler = ON;

DELIMITER $$

CREATE DEFINER = 'app_user'@'%'
EVENT app_db.ev_cleanup_orders
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
  DELETE FROM app_db.orders
  WHERE created_at < NOW() - INTERVAL 30 DAY;
END$$

DELIMITER ;
===================================================

-- Check scheduler:
SHOW VARIABLES LIKE 'event_scheduler';
===================================================

-- SHOW Events for 1 database
SELECT
  EVENT_SCHEMA,
  EVENT_NAME,
  'EVENT' AS OBJECT_TYPE,
  DEFINER,
  STATUS,
  EVENT_TYPE,
  INTERVAL_VALUE,
  INTERVAL_FIELD,
  STARTS
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA = 'app_db';
===================================================

-- Show EVENTS for ALL user databases
SELECT
  EVENT_SCHEMA,
  EVENT_NAME,
  'EVENT' AS OBJECT_TYPE,
  DEFINER,
  STATUS,
  EVENT_TYPE,
  INTERVAL_VALUE,
  INTERVAL_FIELD,
  STARTS
FROM information_schema.EVENTS
WHERE EVENT_SCHEMA NOT IN (
    'mysql',
    'sys',
    'information_schema',
    'performance_schema'
);
===================================================