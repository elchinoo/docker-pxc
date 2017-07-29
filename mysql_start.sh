#!/bin/bash
set -m

start() {	
	# Initialize database
	if [[ $MYSQL_INITDB -eq "1" ]]; then
		mysqld --initialize-insecure
	fi
	
	if [[ $MYSQ_FORCE_BOOTSTRAP -eq "1" ]]; then
		echo "safe_to_bootstrap: 1" >> $MYSQ_DATADIR/grastate.dat
		MYSQL_BOOTSTRAP="1"
	fi
	
	if [[ $MYSQL_BOOTSTRAP -eq "1" ]]; then
		mysqld_safe --wsrep-new-cluster $MYSQL_EXTRA_OPTS &	
	fi
	
	if [[ $MYSQL_INITDB -eq "1" ]]; then
		echo "Waiting MySQL to start..."
		while ! mysql -e "select 1" &>/dev/null; do   
			sleep 1 # wait for 1 second before check again
		done
		
		# Check if defined user for replication
		if [ ! $MYSQL_REPL_USER ]; then
			MYSQL_REPL_USER="sstuser"
		fi
		
		# Check if defined password for replication user
		if [ ! $MYSQL_REPL_PASSWORD ]; then
			MYSQL_REPL_PASSWORD="p4ssw0rd"
		fi

		# Create replication user for xtrabackup
		echo "Creating xtrabackup replication user and setting privileges..."
		mysql --connect-expired-password -uroot -e "CREATE USER '${MYSQL_REPL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_REPL_PASSWORD}';" &>/dev/null
		if [ $? -eq "1" ]; then
			echo "Error to create xtrabackup user. Exiting!"
			exit
		fi
	
		mysql --connect-expired-password -uroot -e "GRANT PROCESS, RELOAD, LOCK TABLES, REPLICATION CLIENT ON *.* TO '${MYSQL_REPL_USER}'@'localhost';FLUSH PRIVILEGES;" &>/dev/null
		if [ $? -eq "1" ]; then
			echo "Error to give permissions to xtrabackup user. Exiting!"
			exit
		fi;
		
		# Check if user has defined new password for root and change it
		if [ $MYSQL_ROOT_PASSWORD ]; then
			echo "Changing root password to given password..."
			mysql --connect-expired-password -uroot -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_PASSWORD=}');FLUSH PRIVILEGES;" &>/dev/null
			if [ $? -eq "1" ]; then
				echo "Error to change password. Exiting!"
				exit
			fi
		fi
	
		echo "Privileges sett'ed successfully"
		fg
	else
		mysqld_safe $MYSQL_EXTRA_OPTS
	fi
}

start