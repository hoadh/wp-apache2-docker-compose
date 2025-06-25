## Start

```sh
cp .env.example .env
```

## Backup & Restore

| Việc cần làm | Lệnh                                                    |
| ------------ | ------------------------------------------------------- |
| Tạo backup   | `chmod +x backup.sh && ./backup.sh`                     |
| Khôi phục    | `chmod +x restore.sh && ./restore.sh backups/backup_xxx.tar.gz` |

## Structure

```
project-root/
├── docker-compose.yml
├── .env.example
├── wordpress/     # Source WordPress (Or /var/www/html)
├── dbdata/        # MySQL data
├── backup.sh      # Script backup
├── restore.sh     # Script restore
```
