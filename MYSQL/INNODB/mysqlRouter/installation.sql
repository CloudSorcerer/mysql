⭐ Preparation & Prerequisites

Using exact setup:

    Primary → MySQL1 (10.1.0.6)

    Replica → MySQL2 (10.1.0.7)

    Replica → MySQL3 (10.1.0.8)

    Router → InnoDB-router (10.1.0.12)

    datadir: /mysql

    socket: /mysql/mysql.sock

    backups: /backup

    binlogs: /mysql/binlogs/mysql-bin

    OS: RHEL 9 (latest minor update)

    MySQL: 8.4.7

    MySQL Shell: 8.4.7

📌 Install Required Packages

You need:

    mysqlrouter

    mysql client

    mysql-shell

📌 Check Connectivity
telnet 10.1.0.9 3306
# or
nc -vz 10.1.0.9 3306
📌 Bootstrap MySQL Router
sudo -u mysqlrouter mysqlrouter \
  --bootstrap icadmin@10.1.0.9:3306 \
  --directory=/etc/mysqlrouter \
  --user=mysqlrouter \
  --account=mysql_router1@% \
  --account-create=always
📌 Start & Enable Router

(Your commands remained unchanged; execute your usual systemctl start/enable workflow.)
📌 SELinux & Firewall Configuration
firewall-cmd --add-port=6446/tcp --permanent
firewall-cmd --add-port=6447/tcp --permanent
firewall-cmd --add-port=6450/tcp --permanent
firewall-cmd --reload

sestatus

dnf install -y policycoreutils-python-utils

semanage port -a -t mysqld_port_t -p tcp 6446
semanage port -a -t mysqld_port_t -p tcp 6447
semanage port -a -t mysqld_port_t -p tcp 6450
📌 Test Router Endpoints
Read/Write → Port 6446
mysql -h 10.1.0.12 -P 6446 -u icadmin -p
Read/Only → Port 6447
mysql -h 10.1.0.12 -P 6447 -u icadmin -p
📌 Test Through Router (MySQL Shell JS)
session.runSql("SELECT @@hostname, @@read_only").fetchAll()

Result example:
[
    [
        "InnodDB-1",
        0
    ]
]
📌 Same Test (JavaScript – Print)
var r = session.runSql("SELECT @@hostname, @@read_only");
print(r.fetchAll());
📌 Test Through Router (Python Mode)
session.run_sql("SELECT @@hostname, @@read_only").fetch_all()

Result:
[
    [
        "InnodDB-1",
        0
    ]
]
⭐ HERE IS YOUR FINAL ANSWER
✔ Yes — you CAN check all nodes through Router
❌ No — you CANNOT use cluster.status() through Router (must connect directly)
✔ You CAN see all cluster nodes using SQL:
SELECT * FROM mysql_innodb_cluster_metadata.instances\G;
✔ You CAN see Group Replication members:
SELECT * FROM performance_schema.replication_group_members\G;
✔ You CAN test PRIMARY / SECONDARY routing using 6446 and 6447
✔ Router is confirmed working if these SQL checks succeed