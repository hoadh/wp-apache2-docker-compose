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

# === Check argument ===
if [ -z "$1" ]; then
  echo "Usage: $0 <backup_archive.tar.gz>"
  exit 1
fi

BACKUP_ARCHIVE="$1"

if [ ! -f "$BACKUP_ARCHIVE" ]; then
  echo "❌ Backup file not found: $BACKUP_ARCHIVE"
  exit 1
fi

# === Stop containers ===
echo "🛑 Stopping containers..."
docker-compose down

# === Extract archive ===
TMP_RESTORE="./tmp_restore"
mkdir -p "$TMP_RESTORE"
echo "🔓 Extracting archive..."
tar -xzf "$BACKUP_ARCHIVE" -C "$TMP_RESTORE"

# === Start DB only ===
echo "🚀 Starting DB container..."
docker-compose up -d db

# Wait for DB ready
echo "⏳ Waiting for MySQL to be ready..."
until docker exec "$DB_CONTAINER" mysqladmin ping -u"$DB_USER" -p"$DB_PASSWORD" --silent &> /dev/null; do
  sleep 2
done

# === Restore DB ===
echo "💾 Restoring database..."
docker exec -i "$DB_CONTAINER" sh -c "export MYSQL_PWD=${DB_PASSWORD}; exec mysql -u${DB_USER} ${DB_NAME}" < "$TMP_RESTORE"/db_*.sql

# === Restore WordPress files ===
echo "📂 Restoring WordPress files..."
# If using bind mount, replace directly:
if [ -d ./wordpress_html ]; then
  echo "🗂 Using local bind mount ./wordpress_html ..."
  rsync -av --delete "$TMP_RESTORE"/html_*/ ./wordpress_html/
else
  echo "🚚 Copying via docker cp ..."
  docker cp "$TMP_RESTORE"/html_*/* "${WORDPRESS_CONTAINER}:${FILES_DIR}"
fi

# === Cleanup ===
rm -rf "$TMP_RESTORE"

# === Start all containers ===
echo "🔁 Starting all containers..."
docker-compose up -d

echo "✅ Restore completed: $BACKUP_ARCHIVE"
