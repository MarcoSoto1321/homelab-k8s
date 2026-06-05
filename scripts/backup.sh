#!/usr/bin/env bash
# =============================================================================
# backup.sh — Homelab Docker Backup (Fase 0 / Pre-migración K8s)
# =============================================================================
# Hace backup de todos los volúmenes y bind mounts críticos antes de la
# migración a K3s. Crea tarballs con timestamp en $BACKUP_DIR.
#
# Uso:
#   ./backup.sh              # Backup completo
#   ./backup.sh vaultwarden  # Backup de un servicio específico
#
# Requisitos: bash, tar, docker (con acceso root o grupo docker)
# =============================================================================

set -euo pipefail

# --- Configuración -----------------------------------------------------------
BACKUP_DIR="${BACKUP_DIR:-/home/soreck/backups/pre-k8s}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_ROOT="${BACKUP_DIR}/${TIMESTAMP}"
LOG_FILE="${BACKUP_ROOT}/backup.log"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Definición de servicios -------------------------------------------------
# Formato: "nombre:tipo:fuente"
#   tipo = "bind"   → fuente es un directorio del host
#   tipo = "volume" → fuente es un volumen nombrado de Docker
declare -a SERVICES=(
  # Críticos
  "vaultwarden:volume:vault_data"
  "bookstack:bind:/home/soreck/docker/bookstack/config"
  "bookstack_db:bind:/home/soreck/docker/bookstack/db"
  "wikijs:bind:/home/soreck/docker/wiki-js/config"
  "wikijs_db:bind:/home/soreck/docker/wiki-js/db"
  "n8n:bind:/home/soreck/docker/n8n/data"
  # Importantes
  "trilium:bind:/home/soreck/docker/trilium/data"
  "vikunja:bind:/home/soreck/docker/vikunja/files"
  # Observabilidad
  "grafana:volume:monitoring_grafana_data"
  "prometheus:volume:monitoring_prometheus_data"
  "prometheus_config:bind:/home/soreck/docker/monitoring/prometheus.yml"
)

# Contenedores a detener durante el backup (datos críticos con riesgo de corrupción)
declare -a STOP_DURING_BACKUP=(
  "vaultwarden"
  "bookstack_db"
  "wiki-js-db-1"
)

# --- Funciones ---------------------------------------------------------------
log() {
  local level="$1"; shift
  local msg="$*"
  local ts; ts=$(date '+%H:%M:%S')
  case "$level" in
    INFO)  echo -e "${BLUE}[${ts}] INFO ${NC} ${msg}" | tee -a "$LOG_FILE" ;;
    OK)    echo -e "${GREEN}[${ts}]  OK  ${NC} ${msg}" | tee -a "$LOG_FILE" ;;
    WARN)  echo -e "${YELLOW}[${ts}] WARN ${NC} ${msg}" | tee -a "$LOG_FILE" ;;
    ERROR) echo -e "${RED}[${ts}] ERR  ${NC} ${msg}" | tee -a "$LOG_FILE" ;;
  esac
}

check_deps() {
  local missing=0
  for cmd in docker tar; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "ERROR: '$cmd' no encontrado" >&2
      missing=1
    fi
  done
  [[ $missing -eq 0 ]] || exit 1
}

backup_bind() {
  local name="$1"
  local source="$2"
  local dest="${BACKUP_ROOT}/${name}.tar.gz"

  if [[ ! -e "$source" ]]; then
    log WARN "[$name] Ruta no existe: $source — omitiendo"
    return 0
  fi

  log INFO "[$name] Bind mount: $source"
  if [[ -f "$source" ]]; then
    # Es un archivo (ej: prometheus.yml), no un directorio
    tar -czf "$dest" -C "$(dirname "$source")" "$(basename "$source")" 2>>"$LOG_FILE"
  else
    tar -czf "$dest" -C "$(dirname "$source")" "$(basename "$source")" 2>>"$LOG_FILE"
  fi
  local size; size=$(du -sh "$dest" | cut -f1)
  log OK "[$name] → ${dest} (${size})"
}

backup_volume() {
  local name="$1"
  local volume="$2"
  local dest="${BACKUP_ROOT}/${name}.tar.gz"

  if ! docker volume inspect "$volume" &>/dev/null; then
    log WARN "[$name] Volumen '$volume' no existe — omitiendo"
    return 0
  fi

  log INFO "[$name] Volumen Docker: $volume"
  docker run --rm \
    -v "${volume}:/data:ro" \
    -v "${BACKUP_ROOT}:/backup" \
    alpine \
    tar -czf "/backup/${name}.tar.gz" -C /data . 2>>"$LOG_FILE"

  local size; size=$(du -sh "$dest" | cut -f1)
  log OK "[$name] → ${dest} (${size})"
}

stop_containers() {
  log INFO "Deteniendo contenedores con datos críticos..."
  for c in "${STOP_DURING_BACKUP[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${c}$"; then
      docker stop "$c" >>"$LOG_FILE" 2>&1
      log OK "Detenido: $c"
    else
      log WARN "Contenedor '$c' no estaba corriendo"
    fi
  done
}

start_containers() {
  log INFO "Reiniciando contenedores..."
  for c in "${STOP_DURING_BACKUP[@]}"; do
    if docker ps -a --format '{{.Names}}' | grep -q "^${c}$"; then
      docker start "$c" >>"$LOG_FILE" 2>&1
      log OK "Iniciado: $c"
    fi
  done
}

print_summary() {
  echo ""
  log INFO "════════════════════════════════════════"
  log INFO "RESUMEN DEL BACKUP"
  log INFO "Directorio: $BACKUP_ROOT"
  log INFO "Archivos generados:"
  for f in "${BACKUP_ROOT}"/*.tar.gz; do
    [[ -f "$f" ]] || continue
    local size; size=$(du -sh "$f" | cut -f1)
    log OK "  $(basename "$f") — ${size}"
  done
  local total; total=$(du -sh "$BACKUP_ROOT" | cut -f1)
  log INFO "Total: ${total}"
  log INFO "Log: $LOG_FILE"
  log INFO "════════════════════════════════════════"
}

# --- Main --------------------------------------------------------------------
main() {
  local filter="${1:-}"

  check_deps

  mkdir -p "$BACKUP_ROOT"
  touch "$LOG_FILE"

  log INFO "Iniciando backup pre-migración K8s — ${TIMESTAMP}"
  log INFO "Destino: $BACKUP_ROOT"
  echo ""

  # Detener contenedores críticos
  stop_containers
  echo ""

  # Ejecutar backups
  for entry in "${SERVICES[@]}"; do
    IFS=':' read -r name type source <<< "$entry"

    # Filtro opcional por nombre
    if [[ -n "$filter" && "$name" != "$filter" ]]; then
      continue
    fi

    case "$type" in
      bind)   backup_bind   "$name" "$source" ;;
      volume) backup_volume "$name" "$source" ;;
      *)      log WARN "Tipo desconocido '$type' para $name" ;;
    esac
  done

  echo ""
  # Reiniciar contenedores
  start_containers

  print_summary
}

# Manejo de señales — asegura que los contenedores se reinicien si el script
# se interrumpe con Ctrl+C o similar
trap 'log ERROR "Script interrumpido — reiniciando contenedores..."; start_containers; exit 1' INT TERM

main "$@"
