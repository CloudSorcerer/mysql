⭐Install MySQL 8.4 + MySQL Shell 8.4 (RHEL 9.7)

This guide covers installing MySQL Server 8.4, configuring a custom data directory, and installing MySQL Shell 8.4 on RHEL 9.7.

========================================================================================================================================
📌 1. Update System Packages

Command:
sudo dnf update -y

What / Why:

    Updates all installed packages to the latest versions

    Prevents dependency or module conflicts before installing MySQL

    Ensures security patches are applied
========================================================================================================================================

📌 2. Add Official MySQL 8.4 YUM Repository

Command:
sudo yum install https://dev.mysql.com/get/mysql84-community-release-el9-2.noarch.rpm -y

Why:

    Enables the official MySQL 8.4 packages for RHEL 9

    Ensures correct server + shell version compatibility
========================================================================================================================================
📌 3. Install MySQL Server

Command:
sudo dnf install mysql-server -y

Why:

    Installs the MySQL Server binaries

    Creates mysql system user and default directories

    Sets up the service under systemd
========================================================================================================================================
📌 4. Create Custom Data Directory (/mysql)
sudo mkdir /mysql
sudo chown -R mysql:mysql /mysql
sudo chmod 750 /mysql

Why:

    Places MySQL data on a dedicated directory (your preferred structure)

    Ensures correct ownership & permissions for MySQL to operate safely
========================================================================================================================================
📌 5. Update MySQL Configuration (/etc/my.cnf)

Edit the file:
sudo vi /etc/my.cnf

Add / modify:
[mysqld]
datadir=/mysql
socket=/mysql/mysql.sock
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

[client]
socket=/mysql/mysql.sock

Why:

    Moves MySQL data directory from /var/lib/mysql → /mysql

    Ensures both server and client use the same custom socket path
========================================================================================================================================
📌 6. Fix /run/mysqld Missing on Reboot (Optional)

Systemd recreates /run on reboot. Create persistent runtime dir:
sudo mkdir -p /run/mysqld
sudo chown -R mysql:mysql /run/mysqld

Reload systemd configuration:
sudo systemctl daemon-reload

========================================================================================================================================
📌 7. Start and Verify MySQL Service
sudo systemctl start mysqld
sudo systemctl status mysqld

Why:

    Starts the database

    Status output helps confirm correct data directory, socket, and log paths
========================================================================================================================================
📌 8. Install MySQL Shell 8.4
sudo yum install mysql-shell -y

Why:

    Provides advanced admin & automation tooling

    Required for InnoDB Cluster, Replication setup, JS/Python API
========================================================================================================================================
📌 9. Retrieve Temporary Root Password

MySQL auto-generates a password on first startup:

Log file example:
A temporary password is generated for root@localhost: Abcdefg!12345

Check it manually:
grep 'temporary password' /var/log/mysqld.log

========================================================================================================================================
📌 10. Run Secure Installation
sudo mysql_secure_installation

You will configure:

    New root password

    Remove anonymous users

    Disable remote root login

    Remove test DB

    Reload privilege tables

✅ Finished!

MySQL Server 8.4 + MySQL Shell 8.4 are now installed and configured with a custom data directory.