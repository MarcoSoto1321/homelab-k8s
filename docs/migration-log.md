# Bitácora de Migración

---

## Fase 0 — Preparación ✅

**Fecha:** Junio 2026

### Completado

- [x] Análisis de infraestructura Docker existente (24 contenedores activos)
- [x] Identificación de volúmenes nombrados y bind mounts por servicio
- [x] Script de backup (`scripts/backup.sh`) con soporte para bind mounts y volúmenes Docker
- [x] Backup completo ejecutado exitosamente en `/home/soreck/backups/pre-k8s/20260605_140133`
  - 11 servicios respaldados, 523 MB total
  - Vaultwarden, Bookstack+DB, Wiki.js+DB, n8n, Trilium, Vikunja, Grafana, Prometheus
- [x] Documentación de puertos y variables de entorno (`docs/services.md`)
- [x] Creación del repositorio `homelab-k8s`

### Hallazgos durante Fase 0

- **Firefly III** corre en Docker pero no estaba en el inventario inicial — tiene volúmenes
  `fireflyiii_firefly_iii_db` y `fireflyiii_firefly_iii_upload`. Evaluar si incluir en migración.
- **Unbound** corre en Docker (no bare metal) en puerto 5335 como DNS resolver upstream para PiHole.
- **mi-cv-web** — sitio web personal, imagen custom `web-cv-web`. Evaluar si migrar.
- **DuckDNS** corre en Docker, token en variable de entorno.
- El volumen de Prometheus pesa 482 MB — en K8s arrancar con retención más corta (15d en lugar de default).
- Wiki.js usa un volumen Docker anónimo (hash) además del bind mount de config — respaldado por nombre de volumen.

### Pendiente Fase 0

- [x] Cambiar contraseñas expuestas en variables de entorno (ver `docs/services.md` — columna 🔑)
- [x] Crear repositorio en GitHub y hacer primer push

---

## Fase 1 — Base del Cluster

**Fecha:** Pendiente

### Pendiente

- [x] Instalar K3s en la Pi 5 (single-node, ARM64)
- [x] Verificar coexistencia Docker + K3s
- [x] Configurar `local-path` provisioner apuntando al NVMe
- [x] Verificar Traefik Ingress Controller (viene con K3s)
- [x] Crear namespaces: `apps`, `monitoring`, `infra`
- [-] Configurar kubeconfig y acceso remoto desde Mac/PC

---

## Fase 2 — Servicios Sin Estado

**Fecha:** Pendiente

- [x] Homepage
- [x] Stirling PDF

---

## Fase 3 — Servicios Con Estado

**Fecha:** Pendiente

- [x] Vaultwarden
- [x] n8n
- [x] Trilium
- [x] Vikunja

---

## Fase 4 — Servicios Con Base de Datos

**Fecha:** Pendiente

- [x] Bookstack + MariaDB
- [x] Wiki.js + PostgreSQL

---

## Fase 5 — Observabilidad

**Fecha:** Pendiente

- [x] Prometheus + Grafana + Loki
- [x] cAdvisor como DaemonSet
- [x] Node Exporter como DaemonSet
- [x] Alertmanager + Telegram

---

## Fase 6 — GitOps

**Fecha:** Pendiente

- [] ArgoCD
- [] Pipeline de actualizaciones

---

## Fase 7 — Multi-Nodo

**Fecha:** Pendiente (cuando llegue hardware)

- [ ] Longhorn storage
- [ ] Segundo nodo worker
