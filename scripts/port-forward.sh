#!/usr/bin/env bash
# =============================================================================
# port-forward.sh — Acceso rápido a servicios K8s durante desarrollo
# =============================================================================
# Uso: ./scripts/port-forward.sh <servicio>
#      ./scripts/port-forward.sh list
# =============================================================================

set -euo pipefail

declare -A SERVICES=(
  ["vaultwarden"]="apps/svc/vaultwarden-svc:8080:80"
  ["bookstack"]="apps/svc/bookstack-svc:8083:80"
  ["wikijs"]="apps/svc/wikijs-svc:3005:3000"
  ["n8n"]="apps/svc/n8n-svc:5678:5678"
  ["trilium"]="apps/svc/trilium-svc:8085:8080"
  ["vikunja"]="apps/svc/vikunja-svc:3456:3456"
  ["homepage"]="apps/svc/homepage-svc:3001:3000"
  ["stirling-pdf"]="apps/svc/stirling-pdf-svc:8081:8080"
  ["grafana"]="monitoring/svc/grafana-svc:3000:3000"
  ["prometheus"]="monitoring/svc/prometheus-svc:9090:9090"
)

list_services() {
  echo "Servicios disponibles:"
  echo ""
  printf "  %-20s %s\n" "NOMBRE" "LOCAL → K8S"
  printf "  %-20s %s\n" "------" "----------"
  for svc in $(echo "${!SERVICES[@]}" | tr ' ' '\n' | sort); do
    IFS=':' read -r ns_svc local_port remote_port <<< "${SERVICES[$svc]}"
    printf "  %-20s localhost:%-6s → %s\n" "$svc" "$local_port" "$remote_port"
  done
}

forward() {
  local name="$1"
  if [[ -z "${SERVICES[$name]+_}" ]]; then
    echo "ERROR: servicio '$name' desconocido"
    echo ""
    list_services
    exit 1
  fi

  IFS=':' read -r ns_svc local_port remote_port <<< "${SERVICES[$name]}"
  IFS='/' read -r namespace type svc_name <<< "$ns_svc"

  echo "Port-forward: localhost:${local_port} → ${svc_name} (${namespace}) :${remote_port}"
  echo "Ctrl+C para detener"
  echo ""

  kubectl port-forward -n "$namespace" "$type/$svc_name" "${local_port}:${remote_port}"
}

case "${1:-}" in
  list|ls|"") list_services ;;
  *) forward "$1" ;;
esac
