⭐ InnoDB Cluster Setup
Using exact setup

    Primary → MySQL1 (10.1.0.6)
    Replica 1 → MySQL2 (10.1.0.7)
    Replica 2 → MySQL3 (10.1.0.8)

    datadir: /mysql
    socket: /mysql/mysql.sock
    backups: /backup
    binlogs: /mysql/binlogs/binlog
    OS: RHEL 9 (latest minor update)
    MySQL: 8.4.7
    MySQL Shell: 8.4.7
==========================================================================================================
1. Pre-Setup Requirements

MySQL must be preinstalled on ALL nodes.
==========================================================================================================
2. Create Required Directories (ALL NODES)

mkdir /mysql
mkdir /mysql/binlogs
mkdir /backup
chown -R mysql:mysql /mysql
chown -R mysql:mysql /mysql/binlogs
chown -R mysql:mysql /backup
==========================================================================================================
3. Update my.cnf (ALL NODES)

Each server must have unique server_id.


vi /etc/my.cnf
------------------------------------------
[mysqld]

datadir=/mysql
socket=/mysql/mysql.sock

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

# ===============================
#   REQUIRED FOR INNODB CLUSTER
# ===============================

server_id=1     # Node specified

# Binary Logging + GTID
log_bin=/mysql/binlogs/mysql-bin
binlog_format=ROW
gtid_mode=ON
enforce_gtid_consistency=ON

# Recommended
binlog_checksum=NONE

# No GROUP REPLICATION settings here!

[client]
socket=/mysql/mysql.sock
==========================================================================================================
4. Restart MySQL (ALL NODES)
sudo systemctl restart mysqld
sudo systemctl status mysqld
==========================================================================================================
5. SSH Configuration (ALL NODES)


vi /etc/ssh/sshd_config

Add (NOT commented):
PermitRootLogin yes
PasswordAuthentication yes

Generate SSH keys:
ssh-keygen -t rsa

ssh-copy-id root@10.1.0.6
ssh-copy-id root@10.1.0.7
ssh-copy-id root@10.1.0.8

Restart SSH:
systemctl restart sshd
------------------------------------------
If issue:
passwd root

Then fix SSH settings as above.
==========================================================================================================
6. Create Cluster Users (Run on ALL NODES)
CREATE USER 'icadmin'@'%'
  IDENTIFIED WITH caching_sha2_password
  BY 'NPO-Deploy$90';

GRANT ALL PRIVILEGES ON *.* TO 'icadmin'@'%' WITH GRANT OPTION;
CREATE USER 'repl'@'%'
  IDENTIFIED WITH caching_sha2_password
  BY 'NPO-Deploy$90';

GRANT REPLICATION SLAVE, REPLICATION CLIENT
  ON *.* TO 'repl'@'%';

FLUSH PRIVILEGES;
==========================================================================================================
🚀 7. Create the Cluster (on MySQL-1)

Login:
mysqlsh --host=10.1.0.6 --port=3306 --user=icadmin --password

Create cluster:
cluster = dba.create_cluster(
    'icCluster',
    { "localAddress": "10.1.0.6:3306" }
)
==========================================================================================================
🚀 8. Add MySQL-2 and MySQL-3

cluster.add_instance(
    'icadmin@10.1.0.7:3306',
    { "localAddress": "10.1.0.7:33061" }
)

cluster.add_instance(
    'icadmin@10.1.0.8:3306',
    { "localAddress": "10.1.0.8:33061" }
)
==========================================================================================================
9. Check Cluster Status

cluster.status()
==========================================================================================================
10. Configure Auto-Recovery Options

-- Node rejoin attempts:
cluster.set_option("autoRejoinTries", 3)

If rejoin fails → node goes into safe offline mode:
cluster.set_option("exitStateAction", "OFFLINE_MODE")
