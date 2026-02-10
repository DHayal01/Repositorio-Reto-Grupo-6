#!/bin/bash

# Parámetros
SRC_HOST="192.168.100.1" 
SRC_PORT="3306"
SRC_USER="root"
SRC_PASS="PassEDID1!"
SRC_DB="edidbd"

# Destino 1: backup AWS subred privada (misma VPC)
DST1_HOST="192.168.101.2"  
DST1_PORT="3306"
DST1_USER="root"
DST1_PASS="PassEDID1!"
DST1_DB="edidbd"

# Destino 2: backup on-premise
DST2_HOST="192.168.150.2"  # IP pública BBDD Main (o IP on-prem si VPN)
DST2_PORT="3306"
DST2_USER="root"
DST2_PASS="PassEDID1!" 
DST2_DB="edidbd"

# Log
LOG_FILE="/var/log/mysql_replica_multi.log"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

log() {
  echo "[$NOW] - $1 - $2" | tee -a "$LOG_FILE"
}

# Opciones comunes mysqldump
DUMP_OPTS="--single-transaction --routines --triggers --events --skip-lock-tables"

# Replica a destino 1 (AWS backup privada)
log "REPLICA_AWS_BACKUP" "INICIO"
mysqldump -h "$SRC_HOST" -P "$SRC_PORT" -u "$SRC_USER" -p"$SRC_PASS" $DUMP_OPTS "$SRC_DB" \
  | mysql -h "$DST1_HOST" -P "$DST1_PORT" -u "$DST1_USER" -p"$DST1_PASS" "$DST1_DB"

if [ $? -eq 0 ]; then
  log "REPLICA_AWS_BACKUP" "OK"
else
  log "REPLICA_AWS_BACKUP" "ERROR"
  exit 1
fi

# Replica a destino 2 (on-premise)
log "REPLICA_ONPREM_BACKUP" "INICIO"
mysqldump -h "$SRC_HOST" -P "$SRC_PORT" -u "$SRC_USER" -p"$SRC_PASS" $DUMP_OPTS "$SRC_DB" \
  | mysql -h "$DST2_HOST" -P "$DST2_PORT" -u "$DST2_USER" -p"$DST2_PASS" "$DST2_DB"

if [ $? -eq 0 ]; then
  log "REPLICA_ONPREM_BACKUP" "OK"
else
  log "REPLICA_ONPREM_BACKUP" "ERROR"
  exit 1
fi

log "REPLICA_COMPLETA" "FINALIZADA"
