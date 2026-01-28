
DELIMITER $$

CREATE TRIGGER app_db.trg_before_insert_orders
BEFORE INSERT ON app_db.orders
FOR EACH ROW
BEGIN
  SET NEW.created_at = NOW();
END$$

DELIMITER ;

==================================================================================================================
-- Trigger do not calling directly, It runs automatically when the event happens (INSERT, UPDATE, or DELETE)
INSERT INTO app_db.orders (id, amount) VALUES (1, 100);


==================================================================================================================
-- SHOW Triggers for 1 database
SELECT
  TRIGGER_SCHEMA,
  DEFINER,
  TRIGGER_NAME,
  EVENT_MANIPULATION,
  EVENT_OBJECT_TABLE,
  ACTION_TIMING,
  CREATED
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'app_db';
==================================================================================================================

-- Show Triggers for all db
SELECT
  TRIGGER_SCHEMA,
  DEFINER,
  TRIGGER_NAME,
  EVENT_MANIPULATION,
  EVENT_OBJECT_TABLE,
  ACTION_TIMING,
  CREATED
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA NOT IN (
    'mysql',
    'sys',
    'information_schema',
    'performance_schema'
)
ORDER BY TRIGGER_SCHEMA, TRIGGER_NAME;
