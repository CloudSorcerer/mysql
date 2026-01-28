MySQL InnoDB ClusterSet Deployment Guide (MySQL 8.4.7 on AlmaLinux 9.7)

Overview: This guide walks through deploying a full InnoDB ClusterSet for MySQL 8.4.7 on AlmaLinux 9.7 (“Moss Jungle Cat”). We will set up two InnoDB Clusters (each with three MySQL instances) and link them into a ClusterSet named clusterSet for cross-site high availability. The topology is as follows:

    Cluster 1: Name mysqlclusterset1 (primary cluster, e.g. Site A) – Three nodes: innodb-a1 (primary, 192.168.80.160), innodb-a2 (secondary, 192.168.80.161), innodb-a3 (secondary, 192.168.80.162). Cluster’s management network address: 192.168.80.144.

    Cluster 2: Name mysqlclusterset2 (replica cluster, e.g. Site B) – Three nodes: innodb-b1 (primary of replica cluster, 192.168.80.163), innodb-b2 (secondary, 192.168.80.164), innodb-b3 (secondary, 192.168.80.165). Cluster’s management address: 192.168.80.147.

    MySQL Routers: Two Router nodes innodb-r1 (192.168.80.166) and innodb-r2 (192.168.80.167) will be configured to route application traffic to the appropriate cluster in the ClusterSet.

Each MySQL server will run on the default port 3306 only (no 33061 port needed) by using MySQL’s Group Replication MYSQL communication stackdev.mysql.com. We will ensure all instances have unique server_id values (using the last IP octet, e.g. 160 for 192.168.80.160), and uniform directories and credentials:

    MySQL data directory: /mysql

    Unix socket: /mysql/mysql.sock

    Binary logs: /mysql/binlogs/binlog (with binlog index in the same directory)

    Backups directory: /backup (for MySQL logical/physical backups as needed)

    Database user credentials: All MySQL administrative accounts (and any replication accounts or Router accounts) will use the password NPO-Deploy$90 for consistency in this guide.

Pre-Deployment Configuration

Before configuring the MySQL clusters, perform the following setup on all MySQL server nodes (innodb-a1, a2, a3, b1, b2, b3):
1. Install MySQL 8.4.7 Server and Shell

    Add MySQL Yum repository: Enable the official MySQL 8.4 repository for RHEL 9 / AlmaLinux 9. For example, download and install the MySQL repository RPM, then disable the distro’s default MariaDB module if applicable. (Refer to MySQL’s documentation or AlmaLinux guides for the exact repository setup steps.)

    Install packages: Use dnf or yum to install the MySQL 8.4 server (mysql-community-server) and MySQL Shell 8.4 (mysql-shell). Example:
    $ sudo dnf install mysql-community-server mysql-shell

    Ensure MySQL Router 8.4 is also installed on the router nodes (innodb-r1, innodb-r2).

    Create required directories: Create the MySQL data directory and related paths, then set correct ownership:
    $ sudo mkdir -p /mysql/binlogs /backup
    $ sudo chown -R mysql:mysql /mysql /backup

    These directories will hold the MySQL datadir, binlogs, and backups respectively.

    SELinux/Firewall configuration: If SELinux is enforcing, apply proper context to /mysql (e.g. using semanage fcontext -a -t mysqld_db_t "/mysql(/.*)?" && restorecon -R /mysql). Open port 3306 on the firewall for MySQL traffic (Group Replication will also use 3306 in MySQL communication stack mode, so no extra port is neededdev.mysql.com). No need to open 33061, since we will not use the legacy XCom communication port.

2. Configure MySQL (my.cnf) for InnoDB Cluster

Edit /etc/my.cnf (or a new file under /etc/my.cnf.d/) on each MySQL node with the following essential settings (the configuration is identical across nodes except for the unique server_id):
[mysqld]

datadir=/mysql
socket=/mysql/mysql.sock

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

# ===============================
#   REQUIRED FOR INNODB CLUSTER
# ===============================

server_id=160     # Node specified

# Binary Logging + GTID
log_bin=/mysql/binlogs/binlog
binlog_format=ROW
gtid_mode=ON
enforce_gtid_consistency=ON

# Recommended
binlog_checksum=NONE

# REQUIRED for Cluster / ClusterSet
log_replica_updates=ON

# Strongly recommended
sync_binlog=1
innodb_flush_log_at_trx_commit=1

# Avoid DNS/hostname surprises
skip-name-resolve=ON
report_host=192.168.80.160
report_port=3306

# No GROUP REPLICATION settings here!

[client]
socket=/mysql/mysql.sock

 

After editing my.cnf, repeat this configuration on each of the six MySQL nodes, changing the server_id IP accordingly for each host.
3. Initialize and Start MySQL Instances

    Initialize datadir (if needed): If the packages didn’t already initialize /mysql, do so with mysqld --initialize --user=mysql --datadir=/mysql (or use --initialize-insecure to allow setting a custom root password later). Otherwise, a default initialization may have occurred during install.

    Start the MySQL service: Enable and start MySQL on each node:
    $ sudo systemctl enable mysqld
    $ sudo systemctl start mysqld

    Confirm MySQL is running on port 3306. If a temporary root password was generated (check the error log in /mysql/mysql.err or /var/log/mysqld.log for a “temporary password”), retrieve it for the next step.

    Secure the installation: On each server, set the MySQL root password to our chosen value (NPO-Deploy$90) if not already set. For example, log in locally and run:
    ALTER USER 'root'@'localhost' IDENTIFIED BY 'NPO-Deploy$90';
    CREATE USER 'root'@'%' IDENTIFIED BY 'NPO-Deploy$90';

    (Allow 'root'@'%' if you plan to connect remotely as root for convenience; otherwise, we’ll use a separate admin user for remote access.)

    Create a Cluster Admin account on all nodes: For InnoDB Cluster deployments, it’s recommended to use a dedicated administration user (instead of root) with the same credentials on every instancedev.mysql.comdev.mysql.com. We will create an admin user icadmin (InnoDB Cluster admin) on each server with full privileges:
    CREATE USER 'icadmin'@'%' IDENTIFIED BY 'NPO-Deploy$90';
    GRANT ALL PRIVILEGES ON *.* TO 'icadmin'@'%' WITH GRANT OPTION;

    (In a stricter environment, you could grant only the necessary privileges for cluster administrationdev.mysql.com, but here we give full admin rights for simplicity.) Ensure 'icadmin'@'%' exists with the same password on every MySQL instance in both clustersdev.mysql.comdev.mysql.com. This uniform account will be used by MySQL Shell to configure and manage the clusters.

    Install Clone Plugin: MySQL 8.0+ includes the Clone plugin for rapid instance provisioning. Verify the clone plugin is installed on each instance (e.g. SHOW PLUGINS LIKE 'clone';). If not, install it:
    INSTALL PLUGIN clone SONAME 'mysql_clone.so';

    The icadmin user was given the global privilege CLONE_ADMIN (via ALL PRIVILEGES), which will allow clone operations for automatic state provisioninglefred.be.

At this point, all six MySQL servers are up and configured for cluster usage (but not yet in any cluster). We have a common admin user (icadmin) on all instances with a common password. We’re ready to create the InnoDB clusters using MySQL Shell.
Deploying the InnoDB Clusters

We will now create two InnoDB Clusters: mysqlclusterset1 (the primary cluster) and mysqlclusterset2 (the replica cluster), and then link them in a ClusterSet. All cluster creation steps use MySQL’s AdminAPI via MySQL Shell 8.4.7 (mysqlsh). We’ll run these steps from a host that can reach the database instances (this could be done from one of the DB servers or a separate admin machine with mysqlsh installed).

Important: Always use MySQL Shell AdminAPI (instead of manual SQL) to configure group replication and clusters once instances are prepared. AdminAPI will handle the correct initialization of Group Replication, synchronization, and metadata.
4. Create the Primary InnoDB Cluster (mysqlclusterset1)

Perform these steps to initiate Cluster 1 on the Site A nodes:

    Connect to the primary node (innodb-a1): Launch MySQL Shell and connect using the cluster admin user. For example:
    $ mysqlsh icadmin@192.168.80.160:3306 --sqlc  # or \connect icadmin@192.168.80.160:3306 in mysqlsh

    Enter the password (NPO-Deploy$90) when prompted. You may use --sqlc (SQL mode) or the default JavaScript mode. The following commands use JS mode (denoted by mysql-js> prompt). Switch to JS if needed with \js.

    Create the cluster: Use the AdminAPI to create a new cluster. We’ll name it mysqlclusterset1 (as per the design). Run:
    mysql-js> var cluster1 = dba.createCluster('mysqlclusterset1', {
                  communicationStack: "MYSQL"
              });

    Explanation: This command validates the current instance (192.168.80.160) for InnoDB Cluster usage and then configures it as the seed for a new clusterdev.mysql.com. We explicitly pass communicationStack: "MYSQL" to ensure the cluster uses the new MySQL communication protocol (avoiding the legacy XCom port) – though in MySQL 8.0.27+ this is the defaultdev.mysql.com. You should see output like:
    Validating instance at icadmin@192.168.80.160:3306...
    Instance configuration is suitable.
    Creating InnoDB cluster 'mysqlclusterset1' on 'icadmin@192.168.80.160:3306'...
    Adding Seed Instance...
    Cluster successfully created. Use Cluster.addInstance() to add MySQL instances.
    At least 3 instances are needed for the cluster to withstand up to one server failure.:contentReference[oaicite:21]{index=21}

    This indicates that the cluster mysqlclusterset1 now exists with innodb-a1 as the only member (the primary).

    Add the remaining instances to Cluster 1: Now integrate the two secondary nodes (innodb-a2 and innodb-a3) into the cluster. Use the Cluster.addInstance() method for each:
    mysql-js> cluster1.addInstance('icadmin@192.168.80.161:3306', 
                 {recoveryMethod: "clone"});

    Provide the password when prompted. The shell will:

        Check that the instance’s configuration is correct (GTIDs, etc.),

        If needed, auto-provision the data using MySQL Clone (recoveryMethod: "clone" forces a clone from the primary),

        Join the instance to the group replication group.

    After a short time, you should see a success message for adding innodb-a2 (192.168.80.161). Repeat for innodb-a3 (192.168.80.162):
    mysql-js> cluster1.addInstance('icadmin@192.168.80.162:3306', 
                 {recoveryMethod: "clone"});

    Each addition will output progress and then a confirmation that the instance was added to the clusterdev.mysql.com. For example:
    Adding instance to the cluster ...
    Validating instance at 192.168.80.161:3306...
    This instance reports its own address as innodb-a2
    Instance configuration is suitable.
    The instance 'icadmin@192.168.80.161:3306' was successfully added to the cluster.:contentReference[oaicite:23]{index=23}

    Verify Cluster 1 status: After adding the secondaries, check the cluster’s status:
    mysql-js> cluster1.status();

    This will show a JSON or table output of the cluster topology. You should see 3 instances (innodb-a1, a2, a3), with one PRIMARY (writer) and two SECONDARY instances, all in the ONLINE status and OK status:

        The primary innodb-a1 should be role HA_PRIMARY (and mode R/W).

        innodb-a2 and innodb-a3 as HA_SECONDARY (read-only), replicating from the primary.

    Ensure Cluster 1 is healthy (all members OK). You now have a functioning InnoDB Cluster mysqlclusterset1 which can serve application traffic (via innodb-a1 for writes). Next, we will set up Cluster 2 and the ClusterSet.

5. Create the InnoDB ClusterSet and Replica Cluster (mysqlclusterset2)

Now we will create the ClusterSet to link Cluster1 and a new Cluster2 for disaster recovery. Cluster2 will initially be empty (standalone servers not yet in a cluster). The ClusterSet creation process will clone data from the primary cluster to the new cluster and set up replication.

Steps (performed in MySQL Shell):

    Create the ClusterSet: Ensure you are still connected to a member of Cluster1 (e.g. icadmin@innodb-a1). Using the existing cluster1 object, call the createClusterSet() method:
    mysql-js> var clusterSet = cluster1.createClusterSet('clusterSet');

    This command designates the current Cluster (mysqlclusterset1) as the primary cluster of a new ClusterSet named clusterSetdev.mysql.com. MySQL Shell will perform validations (all ClusterSet requirements) and then create ClusterSet metadata. On success, you’ll see:
    A new ClusterSet will be created based on the Cluster 'mysqlclusterset1'.
    ClusterSet successfully created. Use ClusterSet.addCluster() to add Replica Clusters to it.
    <ClusterSet: clusterSet>

    At this point, the ClusterSet exists but has only the primary cluster (Cluster1) in it. We will now add Cluster2 as a replica cluster.

    Create the replica InnoDB Cluster (Cluster2) and add it to the ClusterSet: We use ClusterSet.createReplicaCluster() to convert a standalone MySQL instance (innodb-b1 at 192.168.80.163) into a new cluster that replicates from the primary cluster. Run:
    mysql-js> var cluster2 = clusterSet.createReplicaCluster("192.168.80.163:3306", 
                    "mysqlclusterset2", {recoveryProgress: 1});

    Parameters: We specify the target instance (192.168.80.163:3306) which will become the seed for the new replica cluster, and give the new cluster the name mysqlclusterset2. The recoveryProgress: 1 option is used here to show a progress indicator during the initial clone (you can omit it if not needed). You’ll be prompted for the icadmin password for the target instance.

    The Shell will now automatically provision Cluster2 as followsdev.mysql.comdev.mysql.com:

        It checks that 192.168.80.163 is not part of any cluster and meets requirements.

        It clones the entire data set from the primary cluster’s current primary (innodb-a1) to 192.168.80.163, to ensure an up-to-date copy of all databases. (This uses the Clone plugin over the network, leveraging the BACKUP_ADMIN and CLONE_ADMIN privileges we set for icadminlefred.be.)

        It sets up a new InnoDB Cluster on innodb-b1 (with the given name mysqlclusterset2). At this point, that cluster has a single member (innodb-b1 as its primary).

        It configures an asynchronous replication channel named clusterset_replication between Cluster1 and Cluster2dev.mysql.com. This channel is set up such that the primary of Cluster1 (source) will replicate to the primary of Cluster2 (target). MySQL Shell automatically creates a replication user (with a random password) on both clusters for this purpose and configures GTID-based replication with auto-failover for the channeldev.mysql.com. (The replication user and channel are managed internally; you typically do not need to modify them. The replicationAllowedHost is set to allow connections between these cluster primary nodesdev.mysql.com.)

    You will see output indicating the progress: cloning data, establishing replication, etc. For example:
    Setting up replica 'mysqlclusterset2' of cluster 'mysqlclusterset1' at instance 192.168.80.163:3306...
    * Configuring ClusterSet managed replication channel...
    ** Changing replication source of 192.168.80.163:3306 to 192.168.80.160:3306
    * Waiting for instance to synchronize with PRIMARY Cluster...
    Replica cluster created successfully.

    When finished, Cluster2 is created and joined to the ClusterSet as a Replica of Cluster1. There is now a replication channel (clusterset_replication) continuously sending transactions from Cluster1’s primary (innodb-a1) to Cluster2’s primary (innodb-b1)dev.mysql.com. The clusters are in sync (allowing for some small replication lag in normal running).

    Behind the scenes: The ClusterSet ensures that if either cluster elects a new primary, the replication channel adjusts automatically. For example, if Cluster1’s primary changes to innodb-a2, the async replication will detect this and start replicating from the new primary (this is handled by MySQL’s asynchronous connection failover mechanism)dev.mysql.com. Similarly, if Cluster2’s primary changes, it will continue replication on the same channel as the receiver. This provides robust replication continuity without manual reconfiguration.

    Add additional instances to Cluster2: Now that mysqlclusterset2 exists (with innodb-b1 as its only member), we add innodb-b2 and innodb-b3 as secondaries to this cluster for high availability. This process is analogous to how we added instances to Cluster1:
    mysql-js> cluster2.addInstance('icadmin@192.168.80.164:3306', 
                 {recoveryMethod: "clone"});
    mysql-js> cluster2.addInstance('icadmin@192.168.80.165:3306', 
                 {recoveryMethod: "clone"});

    Add each and enter the password when prompted. The Shell will clone data to each new instance from the Cluster2 primary (b1) and join them to the group. After both are added, Cluster2 has three members (innodb-b1 primary, innodb-b2 and innodb-b3 secondaries).

    Check the ClusterSet status: Finally, verify that the ClusterSet is properly configured. Use the clusterSet.status() command in MySQL Shell:
    mysql-js> clusterSet.status({extended: 0});

    This returns a JSON report of the ClusterSet topologydev.mysql.com. Key things to look for:

        clusters.clusterSet (the top-level) should list two clusters: mysqlclusterset1 and mysqlclusterset2.

        mysqlclusterset1 should have "clusterRole": "PRIMARY" and a status of OKdev.mysql.com.

        mysqlclusterset2 should have "clusterRole": "REPLICA" (or SECONDARY) and status OK, indicating it is replicating from the primary cluster.

        Each cluster’s internal status should show their 3 members with one primary and two secondaries all ONLINE.

    For example, the output snippet might resemble:
    "clusters": {
        "mysqlclusterset1": {
            "clusterRole": "PRIMARY",
            "globalStatus": "OK",
            "primaryMember": "innodb-a1:3306",
            ...
        },
        "mysqlclusterset2": {
            "clusterRole": "REPLICA",
            "globalStatus": "OK",
            "primaryMember": "innodb-b1:3306",
            ...
        }
    }

    Both clusters should report OK and the replication channel status for mysqlclusterset2 should indicate it is running (e.g. applierChannelStatus: Running). If everything is OK, the ClusterSet deployment is complete: Cluster1 (mysqlclusterset1) is the active writable cluster, and Cluster2 (mysqlclusterset2) is a synchronized read-only replica (for DR purposes).

At this stage, we have:

    ClusterSet “clusterSet” comprising:

        Primary Cluster: mysqlclusterset1 (innodb-a1 primary, a2/a3 secondaries)

        Replica Cluster: mysqlclusterset2 (innodb-b1 primary, b2/b3 secondaries, replicating from Cluster1)

All writes should be directed to Cluster1’s primary (innodb-a1). Cluster2’s members are read-only replicas (they will refuse writes while in replica role). We will now configure MySQL Router to simplify application connectivity and handle failover.

 
 MySQL Router Configuration for the ClusterSet


MySQL Router 8.4 will be used on innodb-r1 (192.168.80.166) and innodb-r2 (192.168.80.167) to route client connections to the appropriate cluster transparently. The Router instances will be “bootstrapped” against the ClusterSet metadata, making them aware of both clusters and their rolesdev.mysql.com. In normal operation, routers will direct all write traffic to the primary cluster, and can route reads either to the primary cluster or to a specific replica cluster if configureddev.mysql.comdev.mysql.com. If a switchover or failover occurs, the routers automatically detect the new primary cluster and route writes there, with no application changesdev.mysql.com.

Perform these steps on each router node (r1 and r2):

    Install MySQL Router 8.4: (If not already installed.) Since we installed the MySQL packages earlier, this may already be present. Verify by running mysqlrouter --version. If needed, install via the MySQL Yum repository (package mysql-router-community).

1️⃣ Add MySQL official repository (if not already added)
dnf install -y https://repo.mysql.com/mysql84-community-release-el9-1.noarch.rpm

Verify:
dnf repolist | grep mysql
dnf install -y mysql-router
mysqlrouter --version

    Bootstrap the Router against the ClusterSet: On innodb-r1, run:
    mysqlrouter --bootstrap icadmin@192.168.80.160:3306 \
      --account=mysqlrouter1 \
      --name="Router1" \
      --directory /etc/mysqlrouter/router1 \
      --user mysqlrouter \
      --force
    systemctl edit mysqlrouter
    # and add this lines
      
    [Service]
    ExecStart=
    ExecStart=/usr/bin/mysqlrouter -c /etc/mysqlrouter/router1/mysqlrouter.conf

    systemctl daemon-reload
    systemctl restart mysqlrouter


    icadmin@192.168.80.160:3306 is the connection to the primary cluster’s primary instance (Cluster1’s primary). We use the cluster admin user for bootstrapping. This allows Router to retrieve the ClusterSet metadata and create Router user accounts.

        --account=mysqlrouter1 specifies the name for the MySQL user account that the Router will create for itself in the cluster. (Router will create mysqlrouter1@% with a random password by default, and store it in its config.) We could also pre-create this user on all servers with our known password, but by letting bootstrap do it, we ensure proper minimal privileges. (Optional: After bootstrapping, you can alter this user’s password to NPO-Deploy$90 on the clusters if you want it to match the common password policy).

        --name="Router1" sets an identifiable name in the router’s configuration (useful if you have multiple routers; not strictly required).

        --force is included in case a previous bootstrap was done; it forces overwriting any existing config. If bootstrapping fresh, it might not be needed, but it’s safe to include to ensure a clean configdev.mysql.com.

    You will be prompted for icadmin’s password. After that, you should see output similar to:
    # Bootstrapping MySQL Router instance...
    MySQL Router configured for the ClusterSet 'clusterSet':contentReference[oaicite:40]{index=40}.
    Created MySQL Router user 'mysqlrouter1'@'%' with appropriate permissions.
    ...
    Bootstrap complete.

    The bootstrap process does the following:

        Connects to the ClusterSet metadata on Cluster1 and fetches the list of clusters, their endpoints, and roles.

        Creates the router account (mysqlrouter1) on the primary cluster (and thanks to group replication, that user entry replicates to all nodes of Cluster1; it will also propagate to Cluster2 via the async channel so long as system user tables are not filtered).

        Generates a configuration file (JSON and .conf) for MySQL Router with the routing rules. By default, it sets up two main endpoints:

            A read-write port (by default 6446) that routes to the primary cluster’s primary instance (for writes). The Router uses the metadata cache to always target whichever cluster is current PRIMARY.

            A read-only port (by default 6447) that routes to available replicas. By default, MySQL Router in a ClusterSet will route reads to the primary cluster as well (to its secondaries or primary in single-primary mode). However, you can configure it to direct reads to a specific replica cluster if desired (see “named target” mode below).

        The Router config also includes all cluster nodes as backends in a metadata cache section, so it knows how to reach each MySQL instance.

    Repeat the bootstrap on innodb-r2, using a distinct account name: for example:
    mysqlrouter --bootstrap icadmin@192.168.80.160:3306 \
      --account=mysqlrouter2 \
      --name="Router2" \
      --directory /etc/mysqlrouter/router2 \
      --user mysqlrouter \
      --force



    systemctl edit mysqlrouter
    # and add this lines
      
    [Service]
    ExecStart=
    ExecStart=/usr/bin/mysqlrouter -c /etc/mysqlrouter/router2/mysqlrouter.conf

    systemctl daemon-reload
    systemctl restart mysqlrouter

    This will create a mysqlrouter2@% user and config for Router2. (Ensure to use the current primary cluster endpoint for bootstrapping. If Cluster1 is up, using innodb-a1 is fine; otherwise you could bootstrap using any active ClusterSet member – Router will retrieve metadata through itdev.mysql.com.)

    Deploy the Router configuration: The bootstrap places the generated config files in the current directory (or you can specify --directory). For a production setup, you should move these files to /etc/mysqlrouter/ or an appropriate location and set up the Router to run as a service:

        If installed via RPM, a systemd service mysqlrouter may exist. You can copy the config to /etc/mysqlrouter/mysqlrouter.conf and adjust permissions.

        Start the router service: systemctl start mysqlrouter (and enable it on boot).

        Verify Router is running: it should be listening on the default ports 6446 and 6447 (use ss -lnt or netstat).

    On each router node, you’ll have something like:

        TCP 6446 – MySQL Router Read/Write port (clients connect here for read-write sessions; Router will send them to the current primary cluster’s primary node)

        TCP 6447 – MySQL Router Read-Only port (clients connect here for read-mostly sessions; by default Router will load-balance them across secondaries of the primary cluster).

    Advanced Router Modes: By default, both Router instances are configured to “follow the primary” clusterdev.mysql.com. This means all traffic on both ports is directed to whichever cluster is currently primary in the ClusterSet (writes go to the primary instance; reads go to that cluster’s secondaries or primary). You can also configure a router to pin to a specific cluster (the named target mode) for read workloadsdev.mysql.com – e.g., a router at the DR site could be set to send reads to the local (replica) cluster to reduce latency for read-only reporting. Such configuration can be done post-bootstrap using Router’s configuration or MySQL Shell’s Router management functions, but is beyond the basic setup.

    Validate Router connections: Test a connection through the router to ensure it reaches the correct cluster:

        Write test: Connect a MySQL client to innodb-r1’s port 6446 and run SELECT @@hostname, @@port, @@super_read_only;. It should show you the hostname of the current primary DB (e.g. innodb-a1) and @@super_read_only = 0 (meaning it’s writable). The Router has routed you to Cluster1’s primary.

        Read test: Connect to port 6447 and run the same. You should get either the primary or a secondary of the primary cluster, typically with @@super_read_only = 1 if it gave you a secondary. If Router is in default mode, you’ll still be connected to Cluster1 machines. (If you want to test routing to the replica cluster, you’d need to configure Router for that mode or perform a failover which we cover next.)

At this point, the application can use the routers’ addresses instead of direct DB server addresses. We have achieved a fully deployed InnoDB ClusterSet with routers abstracting the connection endpoints.
High Availability and Failover Procedures

One of the main benefits of ClusterSet is simplified disaster recovery and high availability across data centers. In our setup, mysqlclusterset1 is the active primary cluster and mysqlclusterset2 is a passive replica cluster. This section describes how to perform a controlled switchover (for planned maintenance) and an emergency failover (for unplanned outages), and how MySQL Router and the clusters respond in each scenario.
6. Controlled Switchover (Planned Role Change)

A controlled switchover cleanly switches the roles of the primary and replica clusters – promoting the replica cluster to primary, and demoting the original primary cluster to a replica – with no data loss. You would do this for planned maintenance (e.g. to take Cluster1 down for upgrades)dev.mysql.comdev.mysql.com. Both clusters must be fully healthy (status OK) and connected for this operation.

Steps to perform a switchover:

    Ensure clusters are synchronized: Check clusterSet.status() and ensure mysqlclusterset2 (replica) has no lag or only minimal lag behind mysqlclusterset1. If there is lag, either wait for it to catch up or temporarily stop writes if possible. The switchover process will wait for the replica to apply all pending transactions before completingdev.mysql.com.

    Execute the switchover: Connect MySQL Shell to an admin session on any active member of the ClusterSet (for example, innodb-a1 or innodb-b1) and run:
    mysql-js> clusterSet.setPrimaryCluster('mysqlclusterset2');

    This invokes a controlled role switch, making mysqlclusterset2 the new primary clusterdev.mysql.com. Under the hood, Shell will:

        Verify cluster2 is caught up (synchronized) with cluster1dev.mysql.com.

        Lock Cluster1 (to prevent new writes), wait for any last transactions to replicate to Cluster2, then freeze writes on Cluster1 by setting its members to read-only.

        Enable Cluster2 for writes (it becomes the primary cluster) and redirect the ClusterSet replication channel: now Cluster1 will start replicating from Cluster2. (The clusterset_replication channel on Cluster1 gets activated and points to Cluster2’s new primarydev.mysql.com.)

        Mark Cluster1 as a replica in the ClusterSet metadata and Cluster2 as primary.

        Resume operations.

    If successful, the Shell will output confirmation of the primary cluster change. Now:

        Cluster2 (mysqlclusterset2) is the primary cluster (its innodb-b1 is writable).

        Cluster1 (mysqlclusterset1) is demoted to a replica cluster and becomes read-only (its innodb-a1..a3 have super_read_only=1 and are replicating from Cluster2)dev.mysql.com.

    Router and application impact: The MySQL Routers detect the topology change via the metadata cache. They will automatically route new connections to the new primary cluster. Specifically, the routers’ read-write port (6446) will now direct clients to innodb-b1 (Cluster2’s primary) for writesdev.mysql.com. Existing connections might need to reconnect (depending on how the switch was timed relative to application activity), but typically the application should simply experience a brief moment where writes are blocked during the switch. New connections post-switchover go to the correct cluster.

    Optional – update cluster variable:
    After a switchover, you might want to update your application’s view of which site is primary. For instance, if you have a site label or monitoring, note that site B is now primary.

    Perform maintenance on old primary (now replica): You can now safely take Cluster1 offline (since it’s read-only and not serving application writes) for maintenance or upgrades. If you take it down entirely, Router will mark those nodes as unavailable and continue routing to Cluster2. Just note that if Cluster1 is down, you have temporarily lost the DR replica until it’s back – avoid leaving it down longer than necessary.

    Bring Cluster1 back and rejoin (if taken offline): Start all Cluster1 nodes again and use Shell to rejoin the cluster to the ClusterSet if needed. In many cases, if they were not fully offline or if they come back cleanly and still have up-to-date GTIDs (because they were replicating before shutdown), ClusterSet may allow them to catch up. If needed, run:
    mysql-js> clusterSet.rejoinCluster('mysqlclusterset1');

    This will restore Cluster1 as an active replica cluster in the ClusterSet (applying any missed data from Cluster2). Confirm clusterSet.status() shows both clusters OK.

    (Optional) Switch back: To switch back the roles (Cluster1 -> primary again), you would run clusterSet.setPrimaryCluster('mysqlclusterset1') at a suitable time, following a similar process.

7. Emergency Failover (Unplanned Outage Recovery)

An emergency failover is done when the primary cluster becomes completely unavailable (e.g., data center failure or network partition) and you need to quickly promote the replica cluster to restore servicedev.mysql.com. Unlike a switchover, this may happen while the primary cluster is not synchronized (since it’s offline), so some data loss is possible and the original primary will be marked as invalid upon returndev.mysql.com. Use this only in true disaster scenarios.

Scenario: Suppose Cluster1 (mysqlclusterset1) “disappears” due to a catastrophic failure. Cluster2 is behind by some transactions (or at least, we can’t be sure it’s fully caught up). We decide to promote Cluster2 to restore service.

Steps to perform emergency failover:

    Confirm primary is unreachable: Ensure that Cluster1 is truly down or not recoverable in the short term. If it’s a network partition, be aware that the old primary might still be processing transactions isolated from ClusterSet – failover in such a case can lead to divergent data (split-brain)dev.mysql.com. Ideally, ensure the old primary cluster is fully stopped to avoid split-brain.

    Initiate failover to Cluster2: Connect MySQL Shell to a member of Cluster2 (since Cluster1 is down) and run:
    mysql-js> clusterSet.forcePrimaryCluster('mysqlclusterset2');

    This forces the ClusterSet to treat mysqlclusterset2 as the new primary clusterdev.mysql.com. The Shell will:

        Immediately assign Cluster2 as PRIMARY in metadata.

        Mark Cluster1 as INVALIDATED (since it was not gracefully demoted, it’s presumed to have lost or divergent transactions)dev.mysql.com. This prevents Cluster1 from automatically coming back and conflicting.

        Establish that Cluster2 is now active for writes.

    Warning output: The Shell will likely warn that this operation can cause data loss or split-brain if the old primary had unreplicated transactions. By proceeding, we accept that risk given the situation. After execution, Cluster2 is primary.

    Router behavior: Just like with a controlled switchover, routers will detect that Cluster2 is now primary and route all traffic to it. Because Cluster1 is unreachable, routers had probably already stopped sending traffic there. Now with Cluster2 promoted, the routers’ metadata marks Cluster1 as invalid/unavailable, so they will not route any reads or writes to Cluster1 at alldev.mysql.comdev.mysql.com. Applications can continue using the routers and will be connected to Cluster2’s nodes.

    Reintegrate or repair Cluster1: When the issue with Cluster1 is resolved (say the data center comes back), do not immediately put it back into production. Because it was marked invalidated and likely has transactions that Cluster2 never saw, it must be handled carefully:

        If some transactions were lost (never replicated to Cluster2), you must decide if they can be discarded. In many cases, those transactions are considered lost (this is the data loss risk you accept in emergency failover).

        To rejoin Cluster1 to the ClusterSet, you will likely need to remove any errant transactions from Cluster1 or even reclone it from the new primary. The AdminAPI provides clusterSet.rejoinCluster('mysqlclusterset1') which attempts a safe rejoindev.mysql.com. If GTID sets are inconsistent, you may need to remove the cluster and set it up as a replica fresh (similar to how we originally added Cluster2).

        Alternatively, you can completely remove Cluster1 from the ClusterSet (clusterSet.removeCluster('mysqlclusterset1')) and then add it back as a new replica cluster once its data is synchronized or rebuilt.

    Important: The original Cluster1 should not be brought online to accept application traffic or replication until it is properly synchronized; otherwise, you risk split-brain (divergent data sets on clusters)dev.mysql.comdev.mysql.com. Always treat the old primary as potentially tainted after an emergency failoverdev.mysql.com.

    Restore normal redundancy: After Cluster1 is repaired and rejoined as a replica cluster, the ClusterSet is back to having two clusters (Cluster2 primary, Cluster1 replica). You can then do a controlled switchover back if desired or keep Cluster2 as primary going forward.

In summary, ClusterSet gives you a managed way to handle site-level failover. A controlled switchover ensures zero data loss by syncing before role changedev.mysql.com. An emergency failover sacrifices consistency (possibly losing the last transactions on the lost site) to regain availabilitydev.mysql.com. In both cases, MySQL Router transparently follows the changes so that applications always talk to the current primary clusterdev.mysql.com.