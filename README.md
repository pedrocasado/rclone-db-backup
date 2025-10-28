# Backup MySQL to Cloudflare R2 using mysqldump

This Docker app runs a single time, dumping a MySQL database with mysqldump and using rclone to push that data to Cloudflare R2.

You schedule the container to run at whatever interval you want backups to happen.

## Setup

The container needs the environment variables related to MySQL:

- `MYSQL_HOST`: The host to connect to, for example `localhost` or `127.0.0.1`.
- `MYSQL_DATABASE`: The name of the database to dump.
- `MYSQL_PORT`: The port to connect to, defaults to `3306`
- `MYSQL_USER`: Username for MySQL
- `MYSQL_PASSWORD`: Password for MySQL

And these variables related to Cloudflare R2:

- `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY`: An S3-compatible access key
- `R2_ENDPOINT`: The S3 API URL for your R2 account
- `R2_BUCKET`: The name of the bucket to upload to
- `R2_PATH`: A folder within the R2 bucket to upload to, defaults to `"mysql-backup"`

### Railway-specific guide

Tip

You can also deploy MySQL with these backups enabled if you don't have a database yet.

If you're running this container in Railway, you can use shared variables for all the MySQL variables (replace `MySQL` in each expression with the name of your database service):

- `MYSQL_HOST`: `${{MySQL.MYSQLHOST}}`
- `MYSQL_DATABASE`: `${{MySQL.MYSQL_DATABASE}}`
- `MYSQL_PORT`: `${{MySQL.MYSQLPORT}}`
- `MYSQL_USER`: `${{MySQL.MYSQLUSER}}`
- `MYSQL_PASSWORD`: `${{MySQL.MYSQLPASSWORD}}`

Then, in settings, set restart to never and input a cron schedule to backup as often as you'd like.

## Building and Running

Build the Docker image:

```bash
docker build -t rclone-db-backup .
```

Run the container with the necessary environment variables:

```bash
docker run --rm \
  -e MYSQL_HOST=your_mysql_host \
  -e MYSQL_PORT=3306 \
  -e MYSQL_USER=your_mysql_user \
  -e MYSQL_PASSWORD=your_mysql_password \
  -e MYSQL_DATABASE=your_database_name \
  -e R2_ACCESS_KEY_ID=your_r2_access_key \
  -e R2_SECRET_ACCESS_KEY=your_r2_secret_key \
  -e R2_ENDPOINT=your_r2_endpoint \
  -e R2_BUCKET=your_r2_bucket \
  -e R2_PATH=mysql-backup \
  rclone-mysql-backup
```

## Restoring from a backup

1. Install mysql-client and rclone
2. Create the same rclone config file that this container does
3. Run `rclone copy r2:${R2_BUCKET}/${R2_PATH} ./local_backup_folder`
4. Run `gunzip < local_backup_folder/${MYSQL_DATABASE}_${TIMESTAMP}.sql.gz | mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} ${MYSQL_DATABASE}`

### Backup Features

The mysqldump command includes these options:

- `--single-transaction`: Ensures consistent backup for InnoDB tables
- `--routines`: Includes stored procedures and functions
- `--triggers`: Includes triggers
- Output is compressed with gzip for smaller file sizes
