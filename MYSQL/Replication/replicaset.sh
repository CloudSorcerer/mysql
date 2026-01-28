MySQL Replication Setup (MySQL 8.4.7 on RHEL 9)
Environment

    Primary: MySQL1 (10.1.0.4)
    Replica: MySQL2 (10.1.0.5)
    datadir: /mysql
    socket: /mysql/mysql.sock
    backups: /backup
    binlogs: /mysql/binlogs/binlog
    OS: RHEL 9 (latest)
    MySQL: 8.4.7
    MySQL Shell: 8.4.7
===========================================================================================================================
1. Pre-Installation (Both Nodes)
Create directories
mkdir /mysql
mkdir /mysql/binlogs
mkdir /mysql/ssl
mkdir /backup
Set owners
chown -R mysql:mysql /mysql
chown -R mysql:mysql /mysql/binlogs
chown -R mysql:mysql /mysql/ssl
chown -R mysql:mysql /backup

===========================================================================================================================
2. Configure Primary (MySQL1 – 10.1.0.4)

vi /etc/my.cnf
------------------------------------
Content:
[mysqld]

server_id=1

datadir=/mysql
socket=/mysql/mysql.sock

#Configure MySQL SSL
ssl-ca=/mysql/ssl/ca.pem
ssl-cert=/mysql/ssl/server-cert.pem
ssl-key=/mysql/ssl/server-key.pem

#MySQL Logs
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

log_bin=/mysql/binlogs/mysql-bin
binlog_expire_logs_seconds = 604800

binlog_format=ROW
gtid_mode=ON
enforce_gtid_consistency=ON
log_slave_updates=ON

# to allow replica
bind-address=0.0.0.0
===========================================================================================================================
3. Create Replication User (On Primary)

Start MySQL Shell:
mysqlsh
------------------------------------

DROP USER IF EXISTS 'repl'@'10.1.0.5';

CREATE USER 'repl'@'10.1.0.5'
  IDENTIFIED WITH caching_sha2_password
  BY 'NPO-Deploy$90'
  REQUIRE SSL;

GRANT REPLICATION SLAVE ON *.* TO 'repl'@'10.1.0.5';
FLUSH PRIVILEGES;
===========================================================================================================================
4. SSH Configuration for Both Nodes
------------------------------------
# not secure
#Edit sshd_config:
#vi /etc/ssh/sshd_config
#Add (not commented):
#PermitRootLogin yes
#PasswordAuthentication yes


# Generate keys:
ssh-keygen -t rsa
ssh-copy-id root@10.1.0.4
ssh-copy-id root@10.1.0.5

# Restart SSH:

systemctl restart sshd
===========================================================================================================================
5. SSL Configuration
------------------------------------
# On PRIMARY (10.1.0.4)

mkdir -p /mysql/ssl
chown -R /mkdir/ssl
cd /mysql/ssl

#Create SAN config
------------------------------------
vi san.cnf


[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
req_extensions     = req_ext

[ dn ]
CN = 10.1.0.4

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
IP.1 = 10.1.0.4
DNS.1 = 10.1.0.4
------------------------------------
# Create CA Key + Cert
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 3650 -key ca-key.pem -out ca.pem -subj "/CN=MySQL_CA"

# Create Server Key + CSR
openssl genrsa 2048 > server-key.pem
openssl req -new -key server-key.pem -out server.csr -config san.cnf

# Sign Server Certificate
openssl x509 -req -in server.csr -days 3650 \
  -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -out server-cert.pem \
  -extensions req_ext -extfile san.cnf

# Create Client Certificate
openssl genrsa 2048 > client-key.pem
openssl req -new -key client-key.pem -out client.csr -subj "/CN=repl"
openssl x509 -req -in client.csr -days 3650 -CA ca.pem -CAkey ca-key.pem -set_serial 02 -out client-cert.pem

# Copy SSL Files to Replica
scp /mysql/ssl/* root@10.1.0.5:/mysql/ssl/
===========================================================================================================================
6. Dump Database From Primary
------------------------------------

mysqldump -uroot -p --all-databases --single-transaction --routines --triggers --events > /backup/full_backup.sql
scp /backup/full_backup.sql root@10.1.0.5:/backup
===========================================================================================================================
7. Configure Replica (MySQL2 – 10.1.0.5)

vi /etc/my.cnf
------------------------------------

[mysqld]

datadir=/mysql
socket=/mysql/mysql.sock

server_id=2

ssl-ca=/mysql/ssl/ca.pem
ssl-cert=/mysql/ssl/server-cert.pem
ssl-key=/mysql/ssl/server-key.pem

relay_log=/mysql/binlogs/relay-bin
relay_log_index=/mysql/binlogs/relay-bin.index
binlog_expire_logs_seconds = 604800

gtid_mode=ON
enforce_gtid_consistency=ON
log_slave_updates=ON
read_only=ON

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

[client]
socket=/mysql/mysql.sock
===========================================================================================================================
8. Reset Replica Before Restore
------------------------------------
systemctl stop mysqld
rm -rf /mysql/*
chown -R mysql:mysql /mysql

mysqld --initialize --user=mysql --datadir=/mysql
grep 'temporary password' /var/log/mysqld.log

mkdir /mysql/binlogs
chown -R mysql:mysql /mysql

systemctl start mysqld

# Set root password:

mysql -u root -p
ALTER USER 'root'@'localhost' IDENTIFIED BY 'NPO-Deploy$90';

# Copy SSL files again (if needed):
scp /mysql/ssl/* root@10.1.0.5:/mysql/ssl/
===========================================================================================================================
9. Restore Backup on Replica

mysql -u root -p < /backup/full_backup.sql
===========================================================================================================================
10. Replicaset Configuration (Both Nodes)

# Login to MySQL:
INSTALL PLUGIN group_replication SONAME 'group_replication.so';
SET PERSIST group_replication_bootstrap_group=OFF;
SET PERSIST group_replication_recovery_use_ssl=ON;
SHOW VARIABLES LIKE 'server_id';
# Create admin user
CREATE USER 'admin'@'%' IDENTIFIED BY 'NPO-Deploy$90';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
===========================================================================================================================
11. Create Replicaset (On Primary)

rs = dba.create_replica_set("myRs")

rs.add_instance("admin@10.1.0.5:3306")
===========================================================================================================================
12. Check Replicaset Status

rs = dba.get_replica_set()
rs.status()


########################################### ReplicaSet Failover Options ######################################################
ReplicaSet Failover Options
===========================================================================================================================
✅ OPTION 1 — Manual Failover Using MySQL Shell
------------------------------------
# When the PRIMARY fails:

#Connect to any replica:

    mysqlsh admin@ReplicaSet-2:3306 --py

# Run:
    rs = dba.get_replica_set()
    rs.force_primary_instance("ReplicaSet-2:3306")

# What this does

    #Promotes ReplicaSet-2 to PRIMARY
    #Updates ReplicaSet metadata
    #Restores write availability
    #ReplicaSet becomes healthy again

# But: this is still manual failover.
===========================================================================================================================
✅ OPTION 2 — Scripted Failover (Semi-Automatic)

# You can create a script that:

    #Monitors PRIMARY (ping / mysqladmin)

    # When failure is detected → automatically calls MySQL Shell:

# Example:

mysqlsh --py -e "
rs = dba.get_replica_set();
rs.force_primary_instance('ReplicaSet-2:3306');
"

#This creates a semi-automatic failover, triggered by your script.
# Pros

    #Works reliably
    #Faster recovery
    #No manual intervention

# ❌ Cons
    #Not true HA
    #External monitoring logic is required

===========================================================================================================================
❗ WHAT REPLICASET CANNOT DO

ReplicaSet does NOT provide the HA guarantees of InnoDB Cluster.
Not Supported
	

Explanation

🚫 Automatic failover - No native automatic primary switch.
🚫 Quorum - No membership voting.
🚫 Automatic rejoin - Nodes won't auto-heal after failure.
🚫 Synchronous replication - Uses async replication only.
🚫 Write availability after primary failure - Replicas remain read-only until promoted.
🚫 Built-in HA logic  - Must be implemented externally.
	


Conclusion

If your requirement is true automatic high availability, then:
👉 Use InnoDB Cluster instead of ReplicaSet.

ReplicaSet = good for controlled, predictable environments
InnoDB Cluster = real HA with quorum, auto failover, auto recovery