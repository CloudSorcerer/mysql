🔥 InnoDB Cluster – Common Errors & Fixes (Troubleshooting Guide)
✅ 1. Authentication Plugin Errors

❌ Error:
Plugin 'mysql_native_password' is not loaded

✔ Cause:
MySQL 8.4 no longer enables mysql_native_password.

✔ Fix: Use caching_sha2_password
ALTER USER 'user'@'%' IDENTIFIED WITH caching_sha2_password BY 'password';

Or when creating:
IDENTIFIED WITH caching_sha2_password BY 'password';
✅ 2. GTID Disabled (very common on fresh servers)

❌ Error:
enforce_gtid_consistency = OFF → must be ON
gtid_mode = OFF → must be ON

✔ Fix (recommended):
dba.configure_instance('icadmin@ip:3306', {"mycnfPath":"/etc/my.cnf", "restart":True})

AdminAPI automatically fixes:

    GTID

    Binary logs

    Group Replication config

    report_host / report_port

✅ 3. Duplicate server_id

❌ Error:
server_id already being used by instance X

✔ Cause:
All nodes default to server_id=1.

✔ Fix: Assign unique IDs:
10.1.0.9  → server_id=4
10.1.0.10 → server_id=5
10.1.0.11 → server_id=6
✅ 4. Errant GTIDs

❌ Error:
Instance has errant GTIDs

✔ Causes:

    Node executed local transactions before joining

    Node belonged to a different replication group

✔ Fix (best): Use Clone recovery
cluster.add_instance(..., recoveryMethod='clone')

Or when prompted by MySQL Shell:
Choose:
C  (Clone)
✅ 5. Group Replication Not Running After Restart

❌ Errors:
This function is not available through a session to a standalone instance
Group replication is not active
MEMBER_STATE = OFFLINE

✔ Cause:
GR does not auto-start unless configured.

✔ Fix:

In /etc/my.cnf:
loose-group_replication_start_on_boot=ON

Enable auto-rejoin:
cluster.set_option("autoRejoinTries", 3)
cluster.set_option("exitStateAction", "OFFLINE_MODE")

Manually rejoin:
cluster.rejoin_instance('icadmin@node_ip:3306')
✅ 6. Wrong PRIMARY during outage

❌ When connecting to wrong node:
cluster = dba.get_cluster("icCluster")
→ fails with Shell Error: standalone instance

✔ Fix: Identify PRIMARY:
SELECT MEMBER_HOST, MEMBER_ROLE
FROM performance_schema.replication_group_members;

Then connect:
mysqlsh --host=PRIMARY_IP --user=icadmin

And:
cluster = dba.get_cluster("icCluster")
✅ 7. Complete Cluster Outage

All nodes show:
MEMBER_STATE = OFFLINE

✔ Fix:
cluster = dba.reboot_cluster_from_complete_outage("icCluster")

Then rejoin remaining nodes.
✅ 8. Incorrect report_host / localAddress

❌ Error:
Instance reports its own address as hostname instead of IP

✔ Fix (my.cnf):
report_host = 10.1.0.x

Or AdminAPI:
dba.configure_instance(... {"localAddress":"10.1.0.x:3306"})
✅ 9. Port Mismatch (MySQL 8.4 requirement)

❌ Error:
Invalid port for localAddress. When using 'MYSQL' communication stack...

✔ Cause:
MySQL 8.4 uses:
communication_stack = MYSQL

GR must use port 3306.

✔ Fix:
"localAddress": "10.1.0.x:3306"

❗ NOT: 33061
✅ 10. Missing Clone Plugin

❌ Error:
Clone plugin is not installed

✔ Fix:
INSTALL PLUGIN clone SONAME 'mysql_clone.so';

(AdminAPI installs automatically during add_instance())
✅ 11. Firewall Not Open

Symptoms:

    GR cannot connect

    add_instance fails

    Metadata not syncing

Required ports:
3306/tcp      (MySQL)
33060/tcp     (X Protocol - optional)

RHEL commands:
firewall-cmd --add-port=3306/tcp --permanent
firewall-cmd --reload
🚀 12. Authentication Caching Issue

Connection fails even with correct password.

✔ Fix: Disable TLS caching
mysqlsh --ssl-mode=DISABLED

Or:
mysql -h ip -u icadmin -p --ssl-mode=DISABLED
🟩 13. Wrong Hostname Resolution

Symptoms:
Node reports hostname instead of IP.

✔ Fix: /etc/hosts
10.1.0.9   innodb1
10.1.0.10  innodb2
10.1.0.11  innodb3

Or:
report_host=10.1.0.9
🟩 14. SSL / Certificate Errors (VERIFY_IDENTITY)

✔ Ensure SAN includes all IPs.
✔ Use:
--ssl-mode=REQUIRED

instead of:
VERIFY_IDENTITY
🟦 15. Missing binlog directory

Symptoms:

    GTID enablement fails

    log_bin path not found

✔ Fix:
mkdir -p /mysql/binlogs
chown mysql:mysql /mysql/binlogs
