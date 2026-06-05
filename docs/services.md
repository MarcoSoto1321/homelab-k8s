# Inventario de Servicios

> Generado en Fase 0 — Junio 2026. Actualizar conforme avance la migración.

---

## Convenciones

- **Estado migración**: 🐳 Docker | 🔄 Migrando | ☸️ K8s | ⛔ No migrar
- **Secretos**: las variables marcadas con 🔑 contienen credenciales — van en K8s Secret, nunca en el repo

---

## Servicios Críticos

### Vaultwarden
| Campo | Valor |
|---|---|
| **Imagen** | `vaultwarden/server:latest` |
| **Puerto host → contenedor** | `8080 → 80` |
| **URL** | `https://vault.marco-sr.duckdns.org` |
| **Datos** | Volumen nombrado: `vault_data` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `apps` |

Variables de entorno:

| Variable | Valor | Secreto |
|---|---|---|
| `DOMAIN` | `https://vault.marco-sr.duckdns.org` | — |
| `SIGNUPS_ALLOWED` | `false` | — |
| `ADMIN_TOKEN` | *(no expuesto en inspect — configurar en K8s)* | 🔑 |

---

### Nginx Proxy Manager
| Campo | Valor |
|---|---|
| **Imagen** | `jc21/nginx-proxy-manager:latest` |
| **Puertos** | `80→80`, `443→443`, `81→81` (admin UI) |
| **Estado migración** | ⛔ Se mantiene en Docker durante migración |
| **Notas** | Actúa como reverse proxy hacia Traefik. Evaluar reemplazo en Fase 6. |

---

### WireGuard UI
| Campo | Valor |
|---|---|
| **Imagen** | `ngoduykhanh/wireguard-ui:latest` |
| **Puerto** | `51821` (UI) |
| **Estado migración** | ⛔ Bare metal — no migrar |

Variables de entorno:

| Variable | Valor | Secreto |
|---|---|---|
| `WGUI_USERNAME` | `admin` | — |
| `WGUI_PASSWORD` | *(redactado)* | 🔑 |
| `WGUI_CONFIG_ADDR` | `10.8.0.1:51820` | — |
| `SEND_SIGHUP` | `true` | — |

---

## Servicios Importantes

### Bookstack
| Campo | Valor |
|---|---|
| **Imagen** | `lscr.io/linuxserver/bookstack:latest` |
| **Puerto host → contenedor** | `8083 → 80` |
| **URL** | `https://bookstack.marco-sr.duckdns.org` |
| **Datos** | Bind mount: `/home/soreck/docker/bookstack/config` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `apps` |

Variables de entorno:

| Variable | Valor | Secreto |
|---|---|---|
| `APP_URL` | `https://bookstack.marco-sr.duckdns.org` | — |
| `DB_HOST` | `bookstack_db` → `bookstack-db-svc` en K8s | — |
| `DB_DATABASE` | `bookstackapp` | — |
| `DB_USER` | `root` | 🔑 |
| `DB_PASS` | *(redactado)* | 🔑 |
| `APP_KEY` | *(redactado — base64)* | 🔑 |
| `PUID` / `PGID` | `1000` | — |

### Bookstack DB (MariaDB)
| Campo | Valor |
|---|---|
| **Imagen** | `lscr.io/linuxserver/mariadb:latest` |
| **Puerto** | `3306` (interno, no expuesto al host) |
| **Datos** | Bind mount: `/home/soreck/docker/bookstack/db` |
| **Estado migración** | 🐳 Docker |

Variables de entorno:

| Variable | Valor | Secreto |
|---|---|---|
| `MYSQL_DATABASE` | `bookstackapp` | — |
| `MYSQL_USER` | `root` | 🔑 |
| `MYSQL_PASSWORD` | *(redactado)* | 🔑 |
| `MYSQL_ROOT_PASSWORD` | *(redactado)* | 🔑 |

---

### Wiki.js
| Campo | Valor |
|---|---|
| **Imagen** | `ghcr.io/requarks/wiki:2` |
| **Nombre contenedor** | `wiki-js-wikijs-1` |
| **Puerto host → contenedor** | `3005 → 3000` |
| **Datos** | Bind mount: `/home/soreck/docker/wiki-js/config` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `apps` |

Variables de entorno:

| Variable | Valor | Secreto |
|---|---|---|
| `DB_TYPE` | `postgres` | — |
| `DB_HOST` | `db` → `wikijs-db-svc` en K8s | — |
| `DB_PORT` | `5432` | — |
| `DB_NAME` | `wikijs` | — |
| `DB_USER` | `wikijs` | 🔑 |
| `DB_PASS` | *(redactado)* | 🔑 |

### Wiki.js DB (PostgreSQL)
| Campo | Valor |
|---|---|
| **Imagen** | `postgres:15-alpine` |
| **Nombre contenedor** | `wiki-js-db-1` |
| **Puerto** | `5432` (interno) |
| **Datos** | Bind mount: `/home/soreck/docker/wiki-js/db` |

Variables de entorno:

| Variable | Valor | Secreto |
|---|---|---|
| `POSTGRES_DB` | `wikijs` | — |
| `POSTGRES_USER` | `wikijs` | 🔑 |
| `POSTGRES_PASSWORD` | *(redactado)* | 🔑 |

---

### n8n
| Campo | Valor |
|---|---|
| **Imagen** | `n8nio/n8n:latest` |
| **Puerto host → contenedor** | `5678 → 5678` |
| **URL** | `https://n8n.marco-sr.duckdns.org` |
| **Datos** | Bind mount: `/home/soreck/docker/n8n/data` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `apps` |

Variables de entorno:

| Variable | Valor | Secreto |
|---|---|---|
| `N8N_HOST` | `n8n.marco-sr.duckdns.org` | — |
| `N8N_PORT` | `5678` | — |
| `N8N_PROTOCOL` | `https` | — |
| `WEBHOOK_URL` | `https://n8n.marco-sr.duckdns.org/` | — |
| `GENERIC_TIMEZONE` | `America/Mexico_City` | — |
| `N8N_ENCRYPTION_KEY` | *(configurar en K8s — crítico para datos cifrados)* | 🔑 |

> ⚠️ **Importante**: `N8N_ENCRYPTION_KEY` debe ser el mismo valor que usabas en Docker,
> de lo contrario las credenciales almacenadas quedarán inaccesibles.

---

### Trilium
| Campo | Valor |
|---|---|
| **Imagen** | `zadam/trilium:latest` |
| **Puerto** | `8080` (interno, acceso vía proxy) |
| **Datos** | Bind mount: `/home/soreck/docker/trilium/data` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `apps` |

Sin variables de entorno críticas — configuración vive en los datos.

---

### Vikunja
| Campo | Valor |
|---|---|
| **Imagen** | `vikunja/vikunja` |
| **Puerto** | `3456` (interno) |
| **URL** | `https://tasks.marco-sr.duckdns.org` |
| **Datos** | Bind mount: `/home/soreck/docker/vikunja/files` (SQLite) |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `apps` |

Variables de entorno:

| Variable | Valor | Secreto |
|---|---|---|
| `VIKUNJA_DATABASE_TYPE` | `sqlite` | — |
| `VIKUNJA_DATABASE_PATH` | `/app/vikunja/files/vikunja.db` | — |
| `VIKUNJA_SERVICE_PUBLICURL` | `https://tasks.marco-sr.duckdns.org` | — |

---

## Observabilidad

### Grafana
| Campo | Valor |
|---|---|
| **Imagen** | `grafana/grafana:latest` |
| **Puerto host → contenedor** | `3000 → 3000` |
| **Datos** | Volumen nombrado: `monitoring_grafana_data` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `monitoring` |

### Prometheus
| Campo | Valor |
|---|---|
| **Imagen** | `prom/prometheus:latest` |
| **Puerto** | `9090` (interno) |
| **Datos** | Volumen: `monitoring_prometheus_data` + config: `/home/soreck/docker/monitoring/prometheus.yml` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `monitoring` |

### Loki
| Campo | Valor |
|---|---|
| **Imagen** | `grafana/loki:latest` |
| **Puerto host → contenedor** | `3100 → 3100` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `monitoring` |

### Promtail
| Campo | Valor |
|---|---|
| **Imagen** | `grafana/promtail:latest` |
| **Estado migración** | 🐳 Docker → DaemonSet en K8s |

### cAdvisor
| Campo | Valor |
|---|---|
| **Imagen** | `gcr.io/cadvisor/cadvisor-arm64:v0.49.1` |
| **Estado migración** | 🐳 Docker → DaemonSet en K8s |

### Node Exporter
| Campo | Valor |
|---|---|
| **Imagen** | `prom/node-exporter:latest` |
| **Puerto** | `9100` (interno) |
| **Estado migración** | 🐳 Docker → DaemonSet en K8s |

---

## Utilidades

### Homepage
| Campo | Valor |
|---|---|
| **Imagen** | `ghcr.io/gethomepage/homepage:latest` |
| **Puerto host → contenedor** | `3001 → 3000` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `apps` |

Variables de entorno:

| Variable | Valor |
|---|---|
| `HOMEPAGE_ALLOWED_HOSTS` | `homepage.marco-sr.duckdns.org,homepage,192.168.1.100:3001` |

### Stirling PDF
| Campo | Valor |
|---|---|
| **Imagen** | `frooodle/s-pdf:latest` |
| **Puerto host → contenedor** | `8081 → 8080` |
| **Estado migración** | 🐳 Docker |
| **Namespace K8s objetivo** | `apps` |

Variables de entorno:

| Variable | Valor |
|---|---|
| `DOCKER_ENABLE_SECURITY` | `false` |
| `INSTALL_BOOK_AND_ADVANCED_HTML_OPS` | `true` |
| `LANGS` | `es_ES` |

### Portainer
| Campo | Valor |
|---|---|
| **Imagen** | `portainer/portainer-ce:latest` |
| **Puerto** | `9443` (HTTPS) |
| **Estado migración** | ⛔ Se queda en Docker (gestión de Docker) |

### Watchtower
| Campo | Valor |
|---|---|
| **Imagen** | `containrrr/watchtower` |
| **Estado migración** | ⛔ No aplica en K8s — reemplazado por ArgoCD + Renovate |

Variables de entorno:

| Variable | Valor |
|---|---|
| `WATCHTOWER_POLL_INTERVAL` | `86400` (24h) |
| `WATCHTOWER_CLEANUP` | `true` |

### Docker Controller Bot
| Campo | Valor |
|---|---|
| **Imagen** | `dgongut/docker-controller-bot:latest` |
| **Estado migración** | ⛔ Solo útil para Docker |

Variables de entorno:

| Variable | Secreto |
|---|---|
| `TELEGRAM_TOKEN` | 🔑 |
| `TELEGRAM_ADMIN` | 🔑 |

---

## Infraestructura Base (No migrar)

### WireGuard
- Bare metal — infraestructura de red. Si K8s falla, el acceso remoto debe seguir funcionando.

### DuckDNS
| Campo | Valor |
|---|---|
| **Imagen** | `linuxserver/duckdns:latest` |
| **Subdominio** | `marco-sr` |
| **Estado migración** | ⛔ Se queda en Docker o bare metal |

Variables de entorno:

| Variable | Secreto |
|---|---|
| `TOKEN` | 🔑 |
| `SUBDOMAINS` | `marco-sr` |

### Unbound
| Campo | Valor |
|---|---|
| **Imagen** | `nfrastack/unbound:latest` |
| **Puerto** | `5335` (DNS interno) |
| **Estado migración** | ⛔ Infraestructura DNS — no migrar |

---

## Resumen de Secretos para K8s

| Secreto K8s | Namespace | Usado por |
|---|---|---|
| `vaultwarden-secret` | `apps` | `ADMIN_TOKEN` |
| `bookstack-secret` | `apps` | `APP_KEY`, `DB_USER`, `DB_PASS` |
| `bookstack-db-secret` | `apps` | `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD` |
| `wikijs-secret` | `apps` | `DB_USER`, `DB_PASS` |
| `wikijs-db-secret` | `apps` | `POSTGRES_USER`, `POSTGRES_PASSWORD` |
| `n8n-secret` | `apps` | `N8N_ENCRYPTION_KEY` |
| `wireguard-ui-secret` | `infra` | `WGUI_PASSWORD` |
| `duckdns-secret` | `infra` | `TOKEN` |
| `telegram-bot-secret` | `infra` | `TELEGRAM_TOKEN`, `TELEGRAM_ADMIN` |
| `slack-webhook-secret` | `monitoring` | URL webhook Alertmanager |
