#!/bin/bash

set -e

# MySQL credentials
MYSQL_HOST=${MYSQL_HOST:-localhost}
MYSQL_PORT=${MYSQL_PORT:-3306}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_DATABASE=${MYSQL_DATABASE}

# Rclone settings
R2_ACCESS_KEY_ID=${R2_ACCESS_KEY_ID}
R2_SECRET_ACCESS_KEY=${R2_SECRET_ACCESS_KEY}
R2_ENDPOINT=${R2_ENDPOINT}
R2_BUCKET=${R2_BUCKET}
R2_PATH=${R2_PATH:-mysql-backup}

# Backup settings
BACKUP_DIR="/backup"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${MYSQL_DATABASE}_${TIMESTAMP}.sql.gz"

# Create backup directory
mkdir -p ${BACKUP_DIR}

echo "Starting MySQL backup for database: ${MYSQL_DATABASE}"

# Create rclone config
mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf << EOF
[r2]
type = s3
provider = Cloudflare
access_key_id = ${R2_ACCESS_KEY_ID}
secret_access_key = ${R2_SECRET_ACCESS_KEY}
endpoint = ${R2_ENDPOINT}
EOF

# Dump the database and compress
echo "Dumping database..."
mysqldump -h ${MYSQL_HOST} -P ${MYSQL_PORT} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} \
    --single-transaction \
    --routines \
    --triggers \
    ${MYSQL_DATABASE} | gzip > ${BACKUP_FILE}

echo "Backup created: ${BACKUP_FILE}"

# Upload to Cloudflare R2
echo "Uploading to Cloudflare R2..."
rclone copy ${BACKUP_FILE} r2:${R2_BUCKET}/${R2_PATH}/

echo "Backup uploaded successfully to r2:${R2_BUCKET}/${R2_PATH}/"

# Clean up local backup file
rm -f ${BACKUP_FILE}

echo "Backup process completed successfully"
