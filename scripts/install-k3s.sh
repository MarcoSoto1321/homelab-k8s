#!/usr/bin/env bash
# =============================================================================
# install-k3s.sh — Instalación de K3s en Raspberry Pi 5 (ARM64)
# =============================================================================
# Instala K3s en modo single-node con configuración optimizada para Pi 5.
# Docker sigue corriendo en paralelo.
#
# Uso: sudo ./scripts/install-k3s.sh
# =============================================================================

set -euo pipefail

# --- Configuración -----------------------------------------------------------
K3S_VERSION="${K3S_VERSION:-}"   # vacío = latest estable
KUBECONFIG_DEST="${HOME}/.kube/config"

# Colores
GREEN='\033[0;32m'; BLUE='\033[0;34m'; YELLOW='\033[1;33m'; NC='\033[0m'
log() { echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $*"; }
ok()  { echo -e "${GREEN}[$(date '+%H:%M:%S')]  OK${NC} $*"; }
warn(){ echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARN${NC} $*"; }

# --- Verificaciones previas --------------------------------------------------
pre_checks() {
  log "Verificando requisitos previos..."

  # Debe correr como root
  [[ $EUID -eq 0 ]] || { echo "ERROR: ejecutar con sudo"; exit 1; }

  # Verificar arquitectura
  arch=$(uname -m)
  [[ "$arch" == "aarch64" ]] || warn "Arquitectura '$arch' — este script está optimizado para ARM64"

  # Verificar RAM disponible
  ram_mb=$(free -m | awk '/^Mem:/{print $2}')
  log "RAM total: ${ram_mb} MB"
  [[ $ram_mb -ge 4096 ]] || warn "Menos de 4GB RAM — K3s funcionará pero con margen ajustado"

  # Verificar Docker sigue corriendo
  if docker ps &>/dev/null; then
    ok "Docker está corriendo — coexistencia OK"
  else
    warn "Docker no responde — verificar estado antes de continuar"
  fi

  # Verificar cgroups v2
  if [[ -f /sys/fs/cgroup/cgroup.controllers ]]; then
    ok "cgroups v2 activo"
  else
    warn "cgroups v1 detectado — K3s funciona igual pero v2 es preferible"
  fi
}

# --- Instalación K3s ---------------------------------------------------------
install_k3s() {
  log "Instalando K3s..."

  local install_args=(
    # No instalar el flannel CNI por defecto — usar el propio
    # "--flannel-backend=none"  # descomentar si quieres Cilium/Calico
    # Deshabilitar servicelb (usaremos NodePort + Nginx Proxy Manager externo)
    "--disable=servicelb"
    # Traefik SÍ lo queremos (ingress controller)
    # "--disable=traefik"  # NO descomentar
    # Datos en el NVMe (path base de K3s)
    "--data-dir=/var/lib/rancher/k3s"
    # Escribir kubeconfig con permisos accesibles
    "--write-kubeconfig-mode=644"
  )

  if [[ -n "$K3S_VERSION" ]]; then
    export INSTALL_K3S_VERSION="$K3S_VERSION"
    log "Versión específica: $K3S_VERSION"
  fi

  curl -sfL https://get.k3s.io | sh -s - server "${install_args[@]}"

  ok "K3s instalado"
}

# --- Post-instalación --------------------------------------------------------
post_install() {
  log "Configurando post-instalación..."

  # Esperar a que el nodo esté listo
  log "Esperando que el nodo esté Ready..."
  for i in $(seq 1 30); do
    if kubectl get nodes 2>/dev/null | grep -q "Ready"; then
      ok "Nodo listo"
      break
    fi
    sleep 5
    [[ $i -eq 30 ]] && { echo "ERROR: timeout esperando nodo"; exit 1; }
  done

  # Configurar kubeconfig para el usuario que invocó sudo
  REAL_USER="${SUDO_USER:-$USER}"
  REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
  mkdir -p "${REAL_HOME}/.kube"
  cp /etc/rancher/k3s/k3s.yaml "${REAL_HOME}/.kube/config"
  chown "$REAL_USER:$REAL_USER" "${REAL_HOME}/.kube/config"
  chmod 600 "${REAL_HOME}/.kube/config"
  ok "kubeconfig copiado a ${REAL_HOME}/.kube/config"

  # Aplicar namespaces base
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(dirname "$SCRIPT_DIR")"

  if [[ -f "${REPO_ROOT}/k8s/core/namespaces.yaml" ]]; then
    kubectl apply -f "${REPO_ROOT}/k8s/core/namespaces.yaml"
    ok "Namespaces creados: apps, monitoring, infra"
  else
    warn "No se encontró k8s/core/namespaces.yaml — aplicar manualmente"
  fi

  # Verificar storage class
  kubectl get storageclass
}

# --- Verificación final -------------------------------------------------------
verify() {
  log "Verificación final..."
  echo ""
  echo "=== Nodos ==="
  kubectl get nodes -o wide
  echo ""
  echo "=== Pods del sistema ==="
  kubectl get pods -n kube-system
  echo ""
  echo "=== Storage Classes ==="
  kubectl get storageclass
  echo ""
  echo "=== Namespaces ==="
  kubectl get namespaces
  echo ""
  ok "K3s instalado y funcionando"
  echo ""
  echo "Próximos pasos:"
  echo "  1. Verificar que Docker sigue operando: docker ps"
  echo "  2. Acceso remoto: copiar ${HOME}/.kube/config a tu Mac/PC de trabajo"
  echo "  3. Continuar con Fase 2: migrar Homepage y Stirling PDF"
}

# --- Main --------------------------------------------------------------------
main() {
  pre_checks
  echo ""
  install_k3s
  echo ""
  post_install
  echo ""
  verify
}

main "$@"
