# Runbook: Restaurar desde Backup

## Restaurar un PVC desde backup

```bash
# 1. Escalar a 0 el deployment
kubectl scale deployment vaultwarden -n apps --replicas=0

# 2. Obtener path del PVC en disco
PVC_PATH=$(kubectl get pvc vaultwarden-pvc -n apps -o jsonpath='{.spec.volumeName}')

# 3. Restaurar datos
sudo tar -xzf /home/soreck/backups/pre-k8s/<timestamp>/vaultwarden.tar.gz \
  -C /var/lib/rancher/k3s/storage/${PVC_PATH}/

# 4. Restaurar el deployment
kubectl scale deployment vaultwarden -n apps --replicas=1
```
