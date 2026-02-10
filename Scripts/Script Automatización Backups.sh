#!/bin/bash

# Parámetros
SRC_HOST="192.168.100.1" 
SRC_PORT="3306"
SRC_USER="root"
SRC_DB="edidbd"

# Destino 1: backup AWS subred privada (misma VPC)
DST1_HOST="192.168.101.2"  
DST1_PORT="3306"
DST1_USER="root"
DST1_DB="edidbd"

# Destino 2: backup on-premise
DST2_HOST="192.168.150.2"  
DST2_PORT="3306"
DST2_USER="root"
DST2_DB="edidbd"

# Log
LOG_FILE="/backup/logs/mysql_replica.log"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

log() {
  echo "[$NOW] - $1 - $2" | tee -a "$LOG_FILE"
}

# Opciones mysqldump
DUMP_OPTS="--single-transaction --routines --triggers --events --skip-lock-tables"

# Crea directorios si no existen
mkdir -p /backup/logs /backup/credenciales

# Replica AWS backup privada
log "REPLICA_AWS_BACKUP" "INICIO"
mysqldump --defaults-extra-file=/backup/credenciales/mysql_src.cnf -h "$SRC_HOST" -P "$SRC_PORT" -u "$SRC_USER" $DUMP_OPTS "$SRC_DB" \
  | mysql --defaults-extra-file=/backup/credenciales/mysql_dst1.cnf -h "$DST1_HOST" -P "$DST1_PORT" -u "$DST1_USER" "$DST1_DB"

if [ $? -eq 0 ]; then
  log "REPLICA_AWS_BACKUP" "OK"
else
  log "REPLICA_AWS_BACKUP" "ERROR"
  exit 1
fi

# Replica on-premise
log "REPLICA_ONPREM_BACKUP" "INICIO"
mysqldump --defaults-extra-file=/backup/credenciales/mysql_src.cnf -h "$SRC_HOST" -P "$SRC_PORT" -u "$SRC_USER" $DUMP_OPTS "$SRC_DB" \
  | mysql --defaults-extra-file=/backup/credenciales/mysql_dst2.cnf -h "$DST2_HOST" -P "$DST2_PORT" -u "$DST2_USER" "$DST2_DB"

if [ $? -eq 0 ]; then
  log "REPLICA_ONPREM_BACKUP" "OK"
else
  log "REPLICA_ONPREM_BACKUP" "ERROR"
  exit 1
fi

log "REPLICA_COMPLETA" "FINALIZADA"
