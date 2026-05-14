#!/bin/bash
# Backup semanal - TFG S/MIME Monitor
# Se ejecuta via cron cada domingo a las 3:00 AM

BACKUP_DIR="/opt/backups"
FECHA=$(date +%Y%m%d)
ARCHIVO="$BACKUP_DIR/smime-backup-$FECHA.tar.gz"

# Crear directorio si no existe
mkdir -p "$BACKUP_DIR"

# Crear backup
tar czf "$ARCHIVO" \
  /opt/smime-monitor \
  /var/www/luparo/index.html \
  /etc/nginx/nginx.conf \
  /etc/nginx/sites-available/luparo \
  2>/dev/null

# Eliminar backups de más de 8 semanas (56 días)
find "$BACKUP_DIR" -name "smime-backup-*.tar.gz" -mtime +56 -delete

echo "Backup creado: $ARCHIVO"
