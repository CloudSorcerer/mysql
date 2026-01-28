🔍 InnoDB Cluster Diagnostics & Management Commands
✅ 1. Check Cluster Status (MySQL Shell)
cluster.status()
✅ 2. Describe Cluster Topology
cluster.describe()
✅ 3. List All Cluster Options
cluster.options()
🟦 Group Replication Diagnostic Commands (SQL mode — MySQL 8.4.7)
▶ Check Members (most important)
SELECT * FROM performance_schema.replication_group_members\G
▶ Member Statistics (lag, transactions)
SELECT * FROM performance_schema.replication_group_member_stats\G
▶ Replication Channels Status
SELECT *
FROM performance_schema.replication_applier_status_by_worker\G
▶ Check Primary Member
SELECT MEMBER_ID, MEMBER_HOST, MEMBER_PORT, MEMBER_ROLE, MEMBER_STATE
FROM performance_schema.replication_group_members\G
\G
🟪 Plugin & System Checks (SQL)
▶ Verify That Group Replication Plugin Is Loaded
SELECT *
FROM information_schema.plugins
WHERE plugin_name = 'group_replication'\G
▶ Check Plugin Version
SELECT PLUGIN_NAME, PLUGIN_VERSION
FROM information_schema.plugins
WHERE PLUGIN_NAME = 'group_replication';
▶ Check if Group Replication Auto-Start Is Enabled
SELECT @@group_replication_start_on_boot;
🟩 Start / Stop Group Replication (Only When Needed)
▶ Start Group Replication
START GROUP_REPLICATION;
▶ Stop Group Replication
STOP GROUP_REPLICATION;
🟧 InnoDB Cluster Management (MySQL Shell AdminAPI)
▶ Add Instance
cluster.add_instance("user@host:3306")
▶ Remove Instance
cluster.remove_instance("user@host:3306")
▶ Rejoin Instance
cluster.rejoin_instance("user@host:3306")
▶ Set Primary Instance
cluster.set_primary_instance("InnoDB-1:3306")
▶ Force Primary (Emergency Failover)
cluster.force_primary_instance("host:3306")
🟥 Cluster Configuration Options (MySQL Shell)
▶ Get All Options
cluster.options()
▶ Set Option
cluster.set_option("optionName", value)
⭐ Most Useful Options (MySQL 8.4.7)

Option
	

Description

autoRejoinTries
	

Retry count for auto rejoin

exitStateAction
	

What to do when node becomes unstable — OFFLINE_MODE recommended

memberWeight
	

Priority for elections

consistency
	

BEFORE / AFTER / BEFORE_AND_AFTER

expelTimeout
	

Timeout before expelling unreachable node
🟫 Performance & Monitoring (SQL)
▶ Check Replication Delay (Applier Queue)
SELECT *
FROM performance_schema.replication_applier_status_by_coordinator\G
🔥 BONUS: MOST Important Commands (Copy/Paste)
Cluster Health
cluster.status()
Members List
SELECT * FROM performance_schema.replication_group_members\G
Member Statistics
SELECT * FROM performance_schema.replication_group_member_stats\G
Full Topology & Config Summary
cluster.describe()