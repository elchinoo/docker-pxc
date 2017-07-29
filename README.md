# docker-pxc
 Percona XtraDB Cluster is an active/active high availability and high scalability open source solution for MySQL® clustering. It integrates Percona Server and Percona XtraBackup with the Codership Galera library of MySQL high availability solutions in a single package that enables you to create a cost-effective MySQL high availability cluster. Percona XtraDB Cluster has been downloaded over 780,000 times since its launch in April 2012.


## Start a new PXC cluster
It is recommended to run at least 3 nodes in the cluster. The first instance will bootstrap the cluster. To start a new PXC instance is simple:
```bash
docker run \
	-d \
	--name=node1 \
	--network=pxcnet \
	-p 53306:3306 \
	-e MYSQL_INITDB=1  \
	-e MYSQL_BOOTSTRAP=1 \
	-v path/to/node1/data:/var/lib/mysql/data \
	-it elchinoo/pxc:latest
```
There are some important parameters in this snippet:
+ *--name=node1*: This parameter will identify the name of the container inside docker and will be used from PXC nodes to communicate with each other;
+ *--network=pxcnet*: This will create a private network and will allow the nodes to communicate with each other using name;
+ *-e MYSQL_INITDB=1*: This variable is optional. Set to 1 and PXC will try to initialize MySQL Data Directory. It will fail if DATADIR is not empty;
+ *-e MYSQL_BOOTSTRAP=1*: This variable is optional. Set to 1 to bootstrap the cluster using this node;
+ *-v /path/to/node1/data:/var/lib/mysql/data*: This parameter will map a local folder */path/to/node1/data* to MySQL DATADIR inside the container */var/lib/mysql/data*;

It maybe take a couple of minutes to startup depending on your machine. You can check the status in */path/to/node1/data/error.log*.
After the node1 finishes the startup we can start the other nodes:
```bash
# Start node2
docker run \
	-d \
	--name=node2 \
	--network=pxcnet \
	-p 53307:3306 \
	-e MYSQL_EXTRA_OPTS="--wsrep-sst-donor=node1 --wsrep-node-name=node2" \
	-v /path/to/node2:/var/lib/mysql/data \
	-it elchinoo/pxc:latest

# Start node3
docker run \
	--rm -d \
	--name=node3 \
	--network=pxcnet \
	-p 53308:3306 \
	-e MYSQL_EXTRA_OPTS="--wsrep-sst-donor=node1 --wsrep-node-name=node3" \
	-v /path/to/node3:/var/lib/mysql/data \
```
Here we have another important variable *MYSQL_EXTRA_OPTS*. We can use this variable to send extra parameters to *mysqld_safe* and here we are sending the *donor* and the *name of the nodes*. 

After this point we have the cluster running and we can access the nodes:
```bash
docker exec -it node1 /bin/bash

# And the MySQL inside the node
mysql 
```
MySQL can also be accessed outside the docker container and we defined the ports:
+ *node1*: 53306
+ *node2*: 53307
+ *node3*: 53308


## Environment Variables
When you start the PXC image, you can adjust the configuration of the MySQL instance by passing one or more environment variables on the docker run command line. Do note that none of the variables below will have any effect if you start the container with a data directory that already contains a database: any pre-existing database will always be left untouched on container startup.

### MYSQL_ROOT_PASSWORD
This variable is optional and specifies the password that will be set for the MySQL root superuser account.

### MYSQL_EXTRA_OPTS 
This variable is optional. This variable can be used to send extra parameters to *mysqld_safe*.

### MYSQL_INITDB
This variable is optional. Set this variable to 1 to try to initialize a new MySQL Data Directory. It will fail if DATADIR is not empty
	
### MYSQ_FORCE_BOOTSTRAP
This variable is optional. Set this variable to 1 to try to force PXC to bootstrap even if this node was not the last one to stop.

### MYSQL_BOOTSTRAP
This variable is optional. Set this variable to 1 to try to bootstrap the cluster

### MYSQL_REPL_USER
This variable is optional and specifies the user that will be used for xtrabackup during replication process.

### MYSQL_REPL_PASSWORD
This variable is optional and specifies the password to the user that will be used for xtrabackup during replication process.
