# Arquitectura y Decisiones Técnicas

---

## Stack Tecnológico

| Componente | Elección | Razón |
|---|---|---|
| **Distribución K8s** | K3s | ARM64 nativo, ~300 MB RAM vs ~1.5 GB de K8s estándar |
| **Ingress** | Traefik (built-in K3s) | Viene incluido, bien integrado, soporte ARM64 |
| **Storage** | local-path provisioner | Single-node, NVMe local, sin NFS externo |
| **GitOps** | ArgoCD | Sincronización automática desde GitHub |
| **Secretos** | K8s Secrets nativos (fase inicial) → Sealed Secrets o External Secrets (futuro) | Progresivo |

---

## Namespaces

```
apps        → Servicios de usuario (Vaultwarden, Bookstack, n8n, etc.)
monitoring  → Observabilidad (Prometheus, Grafana, Loki, Alertmanager)
infra       → Infraestructura de soporte (DuckDNS, etc.)
```

---

## Almacenamiento

K3s usa el provisioner `local-path` incluido, apuntando al NVMe montado como disco principal.
Cada servicio con estado tiene su propio PVC en `/var/lib/rancher/k3s/storage/`.

**Estrategia de backup de PVCs:**
- Script `backup.sh` en este repo copia los PVCs críticos con timestamp
- Se ejecuta manualmente antes de cambios grandes (automatizar con CronJob en Fase 6)

**Ruta futura (Fase 7 — multi-nodo):**
Migrar de `local-path` a Longhorn para replicación entre nodos.

---

## Red y Acceso Externo

```
Internet → DuckDNS (marco-sr.duckdns.org) → IP pública
         → WireGuard (bare metal, puerto 51820)
         → Nginx Proxy Manager (Docker, 80/443)
              └→ Traefik Ingress Controller (K8s)
                   └→ Services en namespace apps/monitoring
```

**¿Por qué Nginx Proxy Manager se queda en Docker durante la migración?**
Porque es el punto de entrada de todos los servicios. Si lo migramos junto con los servicios,
cualquier error deja todo inaccesible. Se mantiene como proxy externo y apunta al ClusterIP
o NodePort de Traefik. Se evaluará reemplazarlo con Traefik directo en Fase 6.

---

## Secretos

**Regla fundamental: ningún valor real se commitea al repositorio.**

### Flujo de trabajo

Cada app tiene dos archivos de secreto:

- `secret.example.yaml` — commiteado, documenta qué claves existen (sin valores)
- `secret.yaml` — en `.gitignore`, contiene valores reales en base64

### Ejemplo

```yaml
# secret.example.yaml (commiteado)
apiVersion: v1
kind: Secret
metadata:
  name: bookstack-secret
  namespace: apps
type: Opaque
stringData:
  DB_PASS: "CAMBIAR_ESTE_VALOR"
  APP_KEY: "CAMBIAR_ESTE_VALOR"
```

Para aplicar:
```bash
# Los valores en Secret de K8s van en base64
echo -n "mi_password" | base64

# Aplicar al cluster (este archivo NO se commitea)
kubectl apply -f k8s/apps/bookstack/secret.yaml
```

### Futuro: Sealed Secrets o External Secrets Operator
En Fase 6 se evaluará usar Sealed Secrets (cifra el secret para que sea seguro commitear)
o External Secrets Operator (lee de Vault, AWS SSM, etc.).

---

## Estrategia de Migración

**Principio: coexistencia, no big bang.**

Docker y K3s corren en paralelo en la misma Pi. Los servicios se migran uno a uno:

1. Levantar el servicio en K8s
2. Verificar que funciona correctamente (datos, conectividad, proxy)
3. Apuntar Nginx Proxy Manager al nuevo endpoint en K8s
4. Detener el contenedor Docker
5. Marcar como ✅ en este documento

**Orden de migración (menor a mayor riesgo):**

| Orden | Servicio | Riesgo | Razón |
|---|---|---|---|
| 1 | Homepage | Bajo | Sin estado, sin datos críticos |
| 2 | Stirling PDF | Bajo | Sin estado |
| 3 | Vaultwarden | Medio | Datos críticos pero stack simple (un solo contenedor) |
| 4 | n8n | Medio | Estado en un directorio, sin DB externa |
| 5 | Trilium | Medio | Estado simple |
| 6 | Vikunja | Medio | SQLite, fácil de migrar |
| 7 | Bookstack | Alto | Depende de MariaDB |
| 8 | Wiki.js | Alto | Depende de PostgreSQL |
| 9 | Observabilidad | Alto | Stack complejo, pero no crítico para usuarios |

---

## Servicios que NO van a K8s

| Servicio | Razón |
|---|---|
| **WireGuard** | Infraestructura de red base. Si K8s falla, el acceso remoto debe seguir vivo. |
| **PiHole / Unbound** | DNS local. Mismo razonamiento que WireGuard. |
| **Nginx Proxy Manager** | Se mantiene durante migración como reverse proxy externo. |
| **Portainer** | Gestión de Docker — solo tiene sentido fuera de K8s. |
| **DuckDNS** | Servicio de red simple, no tiene sentido moverlo. |

---

## Preparación Multi-Nodo (Fase 7)

Aunque hoy corre en un solo nodo, los manifiestos se diseñan pensando en multi-nodo:

- `nodeSelector` con labels explícitos (no asumir un solo nodo)
- `PodAntiAffinity` en servicios críticos cuando haya más de un nodo
- Evitar `hostPath` — usar PVCs desde el principio
- `resources.requests` y `limits` definidos en todos los Deployments
- Cuando llegue el segundo nodo: migrar storage a Longhorn
