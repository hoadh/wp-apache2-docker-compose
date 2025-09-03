#!/bin/bash

# === CONFIG ===
BACKUP_DIR="./backups"
DB_CONTAINER="db"
WORDPRESS_CONTAINER="wordpress"
FILES_DIR="/var/www/html"

# === Load .env ===
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ .env file not found!"
  exit 1
fi

DB_USER=${MYSQL_USER:-root}
DB_PASSWORD=${MYSQL_PASSWORD:-}
DB_NAME=${MYSQL_DATABASE:-wordpress}

# === Generate timestamp ===
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_NAME="backup_${DATE}.tar.gz"

# === Create backup dir ===
mkdir -p "$BACKUP_DIR"

# === Dump database ===
echo "🔄 Dumping database..."
docker exec "$DB_CONTAINER" sh -c "export MYSQL_PWD=${DB_PASSWORD}; exec mysqldump --no-tablespaces -u${DB_USER} ${DB_NAME}" > "$BACKUP_DIR/db_${DATE}.sql"
if [ $? -ne 0 ]; then
  echo "❌ Database dump failed!"
  exit 1
fi

# === Copy WordPress files ===
echo "📂 Copying WordPress files..."
docker cp "${WORDPRESS_CONTAINER}:${FILES_DIR}" "$BACKUP_DIR/html_${DATE}"

# === Create archive ===
echo "📦 Creating archive..."
tar -czf "$BACKUP_DIR/${BACKUP_NAME}" -C "$BACKUP_DIR" "db_${DATE}.sql" "html_${DATE}"

# === Cleanup ===
rm -rf "$BACKUP_DIR/db_${DATE}.sql" "$BACKUP_DIR/html_${DATE}"

echo "✅ Backup complete: $BACKUP_DIR/${BACKUP_NAME}"
