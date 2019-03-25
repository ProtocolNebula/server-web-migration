#!/bin/bash
# Repository: https://github.com/ProtocolNebula/server-web-migration
# Author: Rubén Arroyo Ceruelo
# This script copy ispconfig domain (single web and mysql)
# and move to another remote server (ispconfig or not).
# Remote MySQL and folder must exist

#-----------------
# STEP 0 - Configure
# You can set here the default parameters or pass by parameters
# For more information execute ./migrate.sh -h
#-----------------

## DEFAULT SETTINGS

# LOCAL folder settings
localFolderTemp=~/temp_migration/
localFolderMigrate=

# LOCAL mysql settings 
localDatabaseHost=localhost
localDatabaseUser=root
localDatabasePassword=
localDatabaseName=


# REMOTE SSH settings
remoteSSHUserAndServer=acrejnjh@worldls-202.ca.planethoster.net
remoteSSHPrivateKeyFile=
remoteSSHPort=22

# REMOTE Folder settings
remoteFolderWWW=

# REMOTE MySQL settings (once connected via ssh)
remoteDatabaseHost=localhost
remoteDatabaseUser=root
remoteDatabasePassword=
remoteDatabaseName=

## USAGE HELP
usage () {
cat <<HELP_USAGE
Script that helps migrate folders and databases (mysql) between servers.
Oficial repository: https://github.com/ProtocolNebula/server-web-migration

Usage:	$0 [OPTIONS]

You can do:
	Only WWW migration (set only folder parameters)
	Only MySQL migration (set only MySQL parameters)
	Full migration (set both parameters)
	Only create local files (set only local parameters)
	Full migration  (set local and remote parameters)

OPTIONS
	GENERAL
	--local-folder-temp			DEFAULT: ${localFolderTemp}

	SSH SETTINGS
	--remote-ssh-user-server
	--remote-ssh-port			DEFAULT: ${remoteSSHPort}
	-i | --remote-ssh-private-key-file	If not setted, password will prompted

	FOLDERS
	-s | --local-folder-migrate		
	-d | --remote-folder-migrate

	DATABASE (MYSQL)
	--local-db-user
	--local-db-password
	--local-db-name
	--remote-db-user
	--remote-db-password
	--remote-db-name

EXAMPLE:
	$0 \\
		--local-folder-temp ~/temp_migration/ \\ 	# DEFAULT PARAMETER
		--local-folder-migrate /var/www/domain/web \\
		--remote-folder-migrate /var/www/domain/web \\
		--remote-ssh-user-server user@remoteserver \\
		--remote-ssh-port 22 \\
		-i ~/.ssh/id_rsa \\
		--local-db-user DBUSER \\
		--local-db-password PWD \\
		--local-db-name DBNAME \\
		--remote-db-user DBUSER \\
		--remote-db-password PWD \\
		--remote-db-name DBNAME	

HELP_USAGE
}

## READ INPUT SETTINGS
if [[ "$1" == "" ]]; then
	echo "No options specified."
	echo -e "Showing help menu...\n"
	
	usage
	exit 1
fi

while [[ "$1" != "" ]]; do
	case $1 in
		# Local Folder Settings
		-t | --temp-folder )
			shift
			tempFolder=$1
			;;

		-s | --local-folder-migrate )
			shift
			localFolderMigrate=$1
			;;

		# Local MySQL Settings
		--local-db-host )
			shift
			localDatabaseHost=$1
			;;

		--local-db-user )
			shift
			localDatabaseUser=$1
			;;

		--local-db-password )
			shift
			localDatabasePassword=$1
			;;

		--local-db-name )
			shift
			localDatabaseName=$1
			;;

		# REMOTE - SSH
		--remote-ssh-user-server )
			shift
			remoteSSHUserAndServer=$1
			;;

		-i | --remote-ssh-private-key-file )
			shift
			remoteSSHPrivateKeyFile=$1
			;;

		--remote-ssh-port )
			shift
			remoteSSHPort=$1
			;;

		# Remote Folder Settings
		-d | --remote-folder-migrate )
			shift
			remoteFolderWWW=$1
			;;

		# Local MySQL Settings
		--remote-db-host )
			shift
			remoteDatabaseHost=$1
			;;

		--remote-db-user )
			shift
			remoteDatabaseUser=$1
			;;

		--remote-db-password )
			shift
			remoteDatabasePassword=$1
			;;

		--remote-db-name )
			shift
			remoteDatabaseName=$1
			;;

		# Other menu
		-h | --help)
			usage
			exit
			;;
		*)
			usage
			exit 1
	esac

	# Remove $1 and move $2 to $1...
	shift
done

echo -e "Starting migration...\n"

## Check all minimal settings
if [ -z "$localFolderTemp" ]; then
	echo 'Local folder temp not defined'; exit 2;
elif [[ -z "$localFolderMigrate" && -z "$localDatabaseName" ]]; then
	echo 'No --local-folder-migrate or --local-db-name defined'; exit 2;
elif [ -n "$remoteSSHUserAndServer" ]; then
	if [[ -n "$localFolderMigrate" && -z "$remoteFolderWWW" ]]; then
		echo '--remote-folder-migrate null but --local-migrate-folder defined'; exit 2;
	elif [[ -z "$localDatabaseName"  && -n "$remoteDatabaseName" ]]; then
		echo '--local-database-name null but --remote-database-name defined'; exit 2;
	elif [[ -n "$localDatabaseName"  && -z "$remoteDatabaseName" ]]; then
		echo '--remote-database-name but --local-database-name defined'; exit 2;
	fi
fi;


echo "Create / Wipe temporal folder (${localFolderTemp})"
mkdir -p ${localFolderTemp}
rm -rf ${localFolderTemp}/{.[!.],}*

#-----------------
# STEP 1 - Prepare backup
#-----------------
ZIP_FILE_NAME=web.zip
ZIP_FILE_PATH=${localFolderTemp}${ZIP_FILE_NAME}

# Dump and ZIP SQL
if [ -n "$localDatabaseName" ]; then
	DB_FILE_PATH=${localFolderTemp}/DB_TO_MIGRATE.sql
	echo "Dumping MySQL database (${localDatabaseName})"
	mysqldump \
	       	-h ${localDatabaseHost} \
		-u ${localDatabaseUser} \
		--password=${localDatabasePassword} \
		${localDatabaseName} > ${DB_FILE_PATH}

	echo "Compressing db file"
	zip -q -j ${ZIP_FILE_PATH} ${DB_FILE_PATH}
fi

# ZIP SQL + files

if [ -n "$localFolderMigrate" ]; then
	echo "Compressing folder to migrate"
	# Zip file from content folder to remove parent path in zip file
	(cd ${localFolderMigrate} && \
		zip -q -r  ${ZIP_FILE_PATH} . && \
		cd -)
fi


#-----------------
# STEP 2 - Copy to remote server
#-----------------

# No migration required?
if [ -z "$remoteSSHUserAndServer" ]; then
	echo "No destination server setted."
	echo "Backup done successfully"
	exit 0
fi

echo "Sending files to remote server"

# Prepare base SCP command to copy files
SCP_COMMAND="scp -P ${remoteSSHPort}"

# Set private key if specified
if [ -n "$remoteSSHPrivateKeyFile" ]; then
	SCP_COMMAND="${SCP_COMMAND} \
	-i ${remoteSSHPrivateKeyFile}"
fi

# Set files and folders to SCP
SCP_COMMAND="${SCP_COMMAND} \
	${ZIP_FILE_PATH} \
	${remoteSSHUserAndServer}:${remoteFolderWWW}"

# Execute final SCP command
#$(${SCP_COMMAND})

echo "Files sended successfully"


#-----------------
# STEP 3 - Restore on remote server
#-----------------

echo "Restoring data on remote server..."

# Main SSH command
SSH_COMMAND="ssh -p ${remoteSSHPort}"

# Add private key file if specified
if [ -n "$remoteSSHPrivateKeyFile" ]; then
	SSH_COMMAND="${SSH_COMMAND} -i ${remoteSSHPrivateKeyFile}"
fi

# Add remote connection data
SSH_COMMAND="${SSH_COMMAND} ${remoteSSHUserAndServer}"

# Connect to remote SSH server and execute batch scripts to unzip and import SQL
${SSH_COMMAND} << EOF
	# Move to remote folder
	cd ${remoteFolderWWW};

	# Unzip file (contain web/mysql)
	unzip -u -q ${ZIP_FILE_NAME};

	# Import mysql if db file
	if [ -n "$remoteDatabaseName" ]; then
		mysql \
			-h ${remoteDatabaseHost} \
			-u ${remoteDatabaseUser} \
			--password=${remoteDatabasePasswiord} \
			${remoteDatabaseName} \
			< DB_TO_MIGRATE.sql
	fi
EOF

echo 'Migration success'

