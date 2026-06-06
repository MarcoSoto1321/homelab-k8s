# Monitoring — Prometheus + Grafana + Alertmanager

Stack de observabilidad desplegado via Helm (`kube-prometheus-stack`) + manifiestos para Loki y Promtail.

## Componentes

| Componente         | Método                       | Namespace  |
| ------------------ | ---------------------------- | ---------- |
| Prometheus         | Helm (kube-prometheus-stack) | monitoring |
| Grafana            | Helm (incluido en el chart)  | monitoring |
| Alertmanager       | Helm (incluido en el chart)  | monitoring |
| Node Exporter      | Helm (DaemonSet incluido)    | monitoring |
| Kube State Metrics | Helm (incluido en el chart)  | monitoring |
| Loki               | Manifiestos                  | monitoring |
| Promtail           | Manifiestos (DaemonSet)      | monitoring |

## Pre-requisitos

```bash
# Agregar repo de Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Verificar versión disponible
helm search repo prometheus-community/kube-prometheus-stack
```

## Instalación

### 1. Crear el Secret de Alertmanager (Telegram)

Antes de instalar el chart, crear el Secret con la configuración de Telegram.
Ver `../alertmanager/secret.example.yaml` para la estructura.

```bash
# Copiar el ejemplo y rellenar con valores reales
cp ../alertmanager/secret.example.yaml /tmp/alertmanager-secret.yaml
# Editar /tmp/alertmanager-secret.yaml con tu bot token y chat ID
kubectl apply -f /tmp/alertmanager-secret.yaml
rm /tmp/alertmanager-secret.yaml
```

### 2. Instalar kube-prometheus-stack

```bash
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values.yaml \
  --version 65.8.1
```

> **Nota:** Fijar la versión del chart garantiza reproducibilidad.
> Consultar la última versión estable en: https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack

### 3. Desplegar Loki y Promtail

```bash
kubectl apply -f ../loki/
kubectl apply -f ../promtail/
```

### 4. Verificar

```bash
# Pods corriendo
kubectl get pods -n monitoring

# PVCs creados
kubectl get pvc -n monitoring

# Ingress de Grafana
kubectl get ingress -n monitoring
```

## Actualización del chart

```bash
helm repo update

helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values values.yaml \
  --version <nueva-version>
```

## Acceso

- **Grafana:** https://grafana.marco-sr.duckdns.org
- **Prometheus (port-forward):** `kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090`
- **Alertmanager (port-forward):** `kubectl port-forward -n monitoring svc/kube-prometheus-stack-alertmanager 9093:9093`

## Desinstalación

```bash
helm uninstall kube-prometheus-stack -n monitoring
# Los PVCs NO se borran automáticamente (ReclaimPolicy: Retain)
# Borrar manualmente si se quiere limpiar todo:
# kubectl delete pvc -n monitoring --all
```
