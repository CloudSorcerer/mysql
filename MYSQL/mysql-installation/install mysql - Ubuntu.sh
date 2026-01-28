📘 MySQL 8.4 LTS Installation Guide

OS: Ubuntu 24.04 LTS
MySQL: 8.4 LTS
MySQL Shell: 8.4
Data directory: /mysql
===================================================================================
1️⃣ Prerequisites
sudo apt update
sudo apt install -y wget gnupg lsb-release ca-certificates

===================================================================================
2️⃣ Remove Ubuntu MySQL (if installed)

Ubuntu repo installs MySQL 8.0 → must be removed.
sudo systemctl stop mysql || true
sudo apt purge -y mysql-server mysql-client mysql-common mysql-shell
sudo rm -rf /var/lib/mysql /etc/mysql
sudo apt autoremove -y

Verify:
mysql --version || true
===================================================================================
3️⃣ Add Oracle MySQL APT Repository (Official)

Download repo package:
wget https://dev.mysql.com/get/mysql-apt-config_0.8.34-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.34-1_all.deb
🔧 IMPORTANT – During configuration

Select:
MySQL Server & Cluster  → mysql-8.4-lts
MySQL Shell            → Enabled

Then update:
sudo apt update
===================================================================================
4️⃣ Install MySQL Server 8.4 + MySQL Shell 8.4
sudo apt install -y mysql-server mysql-shell

Verify versions:
mysql --version
mysqlsh --version

Expected:
mysql  Ver 8.4.x
MySQL Shell 8.4.x
===================================================================================

5️⃣ Stop MySQL (Before Data Directory Change)
sudo systemctl stop mysql
===================================================================================
6️⃣ Create Custom Data Directory /mysql
sudo mkdir -p /mysql
sudo chown -R mysql:mysql /mysql
sudo chmod 750 /mysql
===================================================================================
7️⃣ Move Existing MySQL Data
sudo rsync -av /var/lib/mysql/ /mysql/
sudo mv /var/lib/mysql /var/lib/mysql.bak
===================================================================================
8️⃣ Update MySQL Configuration

Edit config:
sudo vi /etc/mysql/mysql.conf.d/mysqld.cnf

Set ONLY these values:
[mysqld]
datadir=/mysql
socket=/mysql/mysql.sock

pid-file=/mysql/mysql.pid
log-error=/mysql/mysql-error.log

Edit config:
sudo vi /etc/mysql/my.cnf
[client]
socket=/mysql/mysql.sock
===================================================================================
9️⃣ Update AppArmor (Mandatory on Ubuntu)

Edit profile:
sudo nano /etc/apparmor.d/usr.sbin.mysqld

Add both lines:
/mysql/ r,
/mysql/** rwk,

Reload AppArmor:
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.mysqld
===================================================================================
🔟 Start MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

Check status:
systemctl status mysql
1️⃣1️⃣ Verify Data Directory
mysql -uroot -p -e "SELECT @@datadir;"

Expected:
/mysql/
1️⃣2️⃣ Secure MySQL Installation
sudo mysql_secure_installation # Password: root

Recommended answers:
VALIDATE PASSWORD: optional
Remove anonymous users: Y
Disallow remote root login: Y
Remove test database: Y
Reload privileges: Y
1️⃣3️⃣ Firewall Configuration (UFW)

Enable firewall:
sudo ufw enable

Allow MySQL:
sudo ufw allow 3306/tcp
sudo ufw reload

Check:
sudo ufw status
1️⃣4️⃣ MySQL Shell Basic Test
mysqlsh

Connect locally:
\connect root@localhost
\status
