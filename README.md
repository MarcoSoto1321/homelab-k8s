# homelab-k8s

Migración progresiva de infraestructura homelab de Docker a Kubernetes (K3s) en una Raspberry Pi 5.

## Hardware

| Componente         | Detalle                               |
| ------------------ | ------------------------------------- |
| **Placa**          | Raspberry Pi 5 — 8 GB RAM             |
| **Almacenamiento** | NVMe M.2 via Argon NEO 5 HAT          |
| **OS**             | Linux ARM64                           |
| **Cluster**        | K3s (single-node → multi-nodo futuro) |

## Arquitectura

```
                    Internet
                        │
                   DuckDNS (marco-sr.duckdns.org)
                        │
                   ┌────▼────┐
                   │  WireGuard (bare metal)       │
                   └────┬────┘
                        │
              ┌─────────▼──────────┐
              │  Nginx Proxy Manager│  (Docker, puerto 80/443)
              └─────────┬──────────┘
                        │
              ┌─────────▼──────────┐
              │  Traefik Ingress   │  (K3s built-in)
              └─────────┬──────────┘
                        │
        ┌───────────────┼───────────────┐
        │               │               │
   namespace:apps  namespace:monitoring  namespace:infra
```

## Servicios

Ver [docs/services.md](docs/services.md) para el inventario completo.

## Plan de Migración

| Fase | Descripción                 | Estado        |
| ---- | --------------------------- | ------------- |
| 0    | Preparación y backups       | ✅ Completada |
| 1    | Base del cluster K3s        | ✅ Completada |
| 2    | Servicios sin estado        | ✅ Completada |
| 3    | Servicios con estado        | ✅ Completada |
| 4    | Servicios con base de datos | ✅ Completada |
| 5    | Observabilidad en K8s       | ✅ Completada |
| 6    | GitOps con ArgoCD           | 🔄 Siguiente  |
| 7    | Multi-nodo                  | ⏳ Pendiente  |

Ver [docs/architecture.md](docs/architecture.md) para decisiones técnicas.
Ver [docs/migration-log.md](docs/migration-log.md) para la bitácora.

## Uso rápido

```bash
# Ver estado del cluster
kubectl get nodes
kubectl get pods -A

# Acceso a servicios durante desarrollo
./scripts/port-forward.sh <servicio>

# Backup manual
sudo ./scripts/backup.sh
```

## Secretos

Los secretos **nunca se commitean**. Cada app tiene un `secret.example.yaml` con las
claves requeridas. Para aplicar en el cluster:

```bash
# Copiar el ejemplo, rellenar valores reales y aplicar
cp k8s/apps/vaultwarden/secret.example.yaml k8s/apps/vaultwarden/secret.yaml
# editar secret.yaml con valores reales (en base64)
kubectl apply -f k8s/apps/vaultwarden/secret.yaml
```

Ver [docs/architecture.md#secretos](docs/architecture.md#secretos) para el flujo completo.
