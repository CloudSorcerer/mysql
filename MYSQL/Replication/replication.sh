MySQL Replication Setup (Classic Async Replication)
Environment

    Primary: MySQL1 (10.1.0.4)
    Replica: MySQL2 (10.1.0.5)
    datadir: /mysql
    socket: /mysql/mysql.sock
    backups: /backup
    binlogs: /mysql/binlogs/binlog
    OS: RHEL 9 (latest minor update)
    MySQL: 8.4.7
    MySQL Shell: 8.4.7

1. Pre-Setup (Both Nodes)
MySQL must already be installed.

Run on both nodes:
mkdir /mysql
mkdir /mysql/binlogs
mkdir /mysql/ssl
mkdir /backup

chown -R mysql:mysql /mysql
chown -R mysql:mysql /mysql/binlogs
chown -R mysql:mysql /mysql/ssl
chown -R mysql:mysql /backup
2. Configure Primary (MySQL1 – 10.1.0.4)

=========================================================================================
vi /etc/my.cnf
----------------------------------
[mysqld]

server_id=1

datadir=/mysql
socket=/mysql/mysql.sock

#Configure MySQL SSL
ssl-ca=/mysql/ssl/ca.pem
ssl-cert=/mysql/ssl/server-cert.pem
ssl-key=/mysql/ssl/server-key.pem
tls_version=TLSv1.2,TLSv1.3

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

[client]
socket=/mysql/mysql.sock
----------------------------------
3. SSH Configuration (Both Nodes)
=========================================================================================
vi /etc/ssh/sshd_config
----------------------------------

# Add:
PermitRootLogin yes
PasswordAuthentication yes

Restart sshd:
systemctl restart sshd
=========================================================================================
Generate and copy keys:
----------------------------------
ssh-keygen -t rsa
ssh-copy-id root@10.1.0.4
ssh-copy-id root@10.1.0.5

=========================================================================================
4. SSL Configuration
----------------------------------
# On PRIMARY (10.1.0.4)

mkdir -p /mysql/ssl
chown -R /mkdir/ssl
cd /mysql/ssl

# Create SAN file
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
----------------------------------
# Create CA

openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 3650 -key ca-key.pem -out ca.pem -subj "/CN=MySQL_CA"

# Create Server Cert
openssl genrsa 2048 > server-key.pem
openssl req -new -key server-key.pem -out server.csr -config san.cnf

# Sign Certificate
openssl x509 -req -in server.csr -days 3650 \
  -CA ca.pem -CAkey ca-key.pem -CAcreateserial \
  -out server-cert.pem \
  -extensions req_ext -extfile san.cnf

# Create Client Cert
openssl genrsa 2048 > client-key.pem
openssl req -new -key client-key.pem -out client.csr -subj "/CN=repl"
openssl x509 -req -in client.csr -days 3650 -CA ca.pem -CAkey ca-key.pem -set_serial 02 -out client-cert.pem

# Copy SSL files to Replica
scp /mysql/ssl/* root@10.1.0.5:/mysql/ssl/

=========================================================================================

5. Replication User (SSL Required) — Primary
----------------------------------

DROP USER IF EXISTS 'repl'@'10.1.0.5';

CREATE USER 'repl'@'10.1.0.5'
  IDENTIFIED WITH caching_sha2_password
  BY 'NPO-Deploy$90'
  REQUIRE SSL;

GRANT REPLICATION SLAVE ON *.* TO 'repl'@'10.1.0.5';
FLUSH PRIVILEGES;
=========================================================================================

6. Backup and Transfer to Replica
mysqldump -uroot -p --all-databases --single-transaction --routines --triggers --events > /backup/full_backup.sql

mysql  -uroot -p -h 10.1.0.5 database < /backup.sql

=========================================================================================
7. Configure Replica (MySQL2 – 10.1.0.5)


vi /etc/my.cnf
----------------------------------
[mysqld]

datadir=/mysql
socket=/mysql/mysql.sock

server_id=2

ssl-ca=/mysql/ssl/ca.pem
ssl-cert=/mysql/ssl/server-cert.pem
ssl-key=/mysql/ssl/server-key.pem
tls_version=TLSv1.2,TLSv1.3

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
=========================================================================================

8. Reset Replica Before Restore

systemctl stop mysqld
rm -rf /mysql/*
chown -R mysql:mysql /mysql

mysqld --initialize --user=mysql --datadir=/mysql
grep 'temporary password' /var/log/mysqld.log

mkdir /mysql/binlogs
chown -R mysql:mysql /mysql

systemctl start mysqld
mysql -u root -p
ALTER USER 'root'@'localhost' IDENTIFIED BY 'NPO-Deploy$90';

# Copy SSL again:
scp /mysql/ssl/* root@10.1.0.5:/mysql/ssl/

=========================================================================================
9. Restore Backup (Replica)
----------------------------------

mysql -u root -p < /backup/full_backup.sql
10. Clean Replica Replication State
STOP REPLICA;
RESET SLAVE ALL;
11. Configure Replication (Replica)

----------------------------------
Login:
mysql -uroot -p

Run:
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='10.1.0.4',
  SOURCE_PORT=3306,
  SOURCE_USER='repl',
  SOURCE_PASSWORD='NPO-Deploy$90',
  SOURCE_SSL=1,
  SOURCE_SSL_CA='/mysql/ssl/ca.pem',
  SOURCE_SSL_CERT='/mysql/ssl/client-cert.pem',
  SOURCE_SSL_KEY='/mysql/ssl/client-key.pem',
  SOURCE_SSL_VERIFY_SERVER_CERT=1,
  SOURCE_AUTO_POSITION=1;

Start replication:
START REPLICA;
SHOW REPLICA STATUS\G

Must be
 MySQL  localhost  SQL > show replica status \G
*************************** 1. row ***************************
             Replica_IO_State: Waiting for source to send event
                  Source_Host: 192.168.80.129
                  Source_User: repl
                  Source_Port: 3306
                Connect_Retry: 60
              Source_Log_File: mysql-bin.000006
          Read_Source_Log_Pos: 198
               Relay_Log_File: relay-bin.000002
                Relay_Log_Pos: 375
        Relay_Source_Log_File: mysql-bin.000006
           Replica_IO_Running: Yes
          Replica_SQL_Running: Yes
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Source_Log_Pos: 198
              Relay_Log_Space: 580
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Source_SSL_Allowed: Yes
           Source_SSL_CA_File: /mysql/ssl/ca.pem
           Source_SSL_CA_Path:
              Source_SSL_Cert: /mysql/ssl/client-cert.pem
            Source_SSL_Cipher:
               Source_SSL_Key: /mysql/ssl/client-key.pem
        Seconds_Behind_Source: 0
Source_SSL_Verify_Server_Cert: Yes
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Source_Server_Id: 1
                  Source_UUID: 652ef6a5-d5b4-11f0-8255-000c290f7624
             Source_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
    Replica_SQL_Running_State: Replica has read all relay log; waiting for more updates
           Source_Retry_Count: 10
                  Source_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Source_SSL_Crl:
           Source_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set: 30e3a66e-d6b2-11f0-855c-000c29467e5d:1-6,
652ef6a5-d5b4-11f0-8255-000c290f7624:1-1035
                Auto_Position: 1
         Replicate_Rewrite_DB:
                 Channel_Name:
           Source_TLS_Version:
       Source_public_key_path:
        Get_Source_public_key: 0
            Network_Namespace:
1 row in set (0.0005 sec)
 MySQL  localhost  SQL >

 

On replication:
mysql -h 10.1.0.4 -urepl -p \
  --ssl-ca=/mysql/ssl/ca.pem \
  --ssl-cert=/mysql/ssl/client-cert.pem \
  --ssl-key=/mysql/ssl/client-key.pem


SHOW SESSION STATUS LIKE 'Ssl_cipher';
SHOW SESSION STATUS LIKE 'Ssl_version';

Must be
mysql> SHOW SESSION STATUS LIKE 'Ssl_version';
+---------------+---------+
| Variable_name | Value   |
+---------------+---------+
| Ssl_version   | TLSv1.3 |
+---------------+---------+
1 row in set (0.00 sec)

mysql> SHOW SESSION STATUS LIKE 'Ssl_cipher';
+---------------+------------------------+
| Variable_name | Value                  |
+---------------+------------------------+
| Ssl_cipher    | TLS_AES_128_GCM_SHA256 |
+---------------+------------------------+
1 row in set (0.00 sec)

 