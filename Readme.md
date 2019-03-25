# Server Web Migration

This script automatize almost migration process from one server to another, you can migrate `Files`, `MySQL` or both at same time (currently only one folder + database per execution).

You can batch this with another batch file to automatize the full translation.

**IMPORTANT:** This script is not Backup oriented, but it can be used to local backup (currently no support resotoration after-backup).

## Requirements

- Bash
- scp (client and server)
- ssh (client and server)

## Usage

### Installation

Download this script and execute:

```bash
chmod +x migrate.sh

# Optionally (to execute from any folder)
ln migrate.sh /bin
```

### View full help

```bash
./migrate.sh -h
```

### Example execution command
```bash
./migrate.sh \
	--local-folder-temp ~/temp_migration/ \
	--local-folder-migrate /var/www/domain/web \
	--remote-folder-migrate /var/www/domain/web \
	--remote-ssh-user-server user@remoteserver \
	--remote-ssh-port 22 \
	-i ~/.ssh/id_rsa \
	--local-db-user DBUSER \
	--local-db-password PWD \
	--local-db-name DBNAME \
	--remote-db-user DBUSER \
	--remote-db-password PWD \
	--remote-db-name DBNAME
```

## Notes

If you need to modify SQL file (paths or something) "on the fly", you can modify the script OR check [PHP - Web and MySQL fast migration](https://github.com/ProtocolNebula/web-and-mysql-fast-migration)

For `ispconfig` backups check: https://github.com/ProtocolNebula/simple-ispconfig-backup
