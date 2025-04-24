# Charts Helm pour RISF et ITSF

Ce répertoire contient les charts Helm pour déployer les applications RISF et ITSF dans un cluster Kubernetes.

## Structure

```
helm/
├── charts/
│   ├── risf/           # Chart Helm pour RISF
│   └── itsf/           # Chart Helm pour ITSF
```

## Prérequis

- Kubernetes 1.19+
- Helm 3.2.0+
- Ingress Controller (comme NGINX Ingress Controller)

## Installation

### RISF

Pour installer le chart RISF avec le nom de release `risf`:

```bash
helm install risf ./charts/risf
```

### ITSF

Pour installer le chart ITSF avec le nom de release `itsf`:

```bash
helm install itsf ./charts/itsf
```

## Configuration

### RISF

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `replicaCount` | Nombre de réplicas du déploiement | `1` |
| `image.repository` | Image Docker à utiliser | `risf` |
| `image.tag` | Tag de l'image Docker | `latest` |
| `image.pullPolicy` | Politique de téléchargement de l'image | `Never` |
| `service.type` | Type de service Kubernetes | `ClusterIP` |
| `ingress.enabled` | Activer l'ingress | `true` |
| `ingress.hosts` | Hôtes pour l'ingress | `[{host: hello-risf.local.domain, paths: [{path: /, pathType: Prefix}]}]` |

### ITSF

| Paramètre | Description | Valeur par défaut |
|-----------|-------------|-------------------|
| `replicaCount` | Nombre de réplicas du déploiement | `1` |
| `image.repository` | Image Docker à utiliser | `itsf` |
| `image.tag` | Tag de l'image Docker | `latest` |
| `image.pullPolicy` | Politique de téléchargement de l'image | `Never` |
| `service.type` | Type de service Kubernetes | `ClusterIP` |
| `ingress.enabled` | Activer l'ingress | `true` |
| `ingress.hosts` | Hôtes pour l'ingress | `[{host: hello-itsf.local.domain, paths: [{path: /, pathType: Prefix}]}]` |
| `persistence.enabled` | Activer la persistance | `true` |
| `persistence.pvc.storage` | Taille du stockage | `50Mi` |

## Désinstallation

### RISF

```bash
helm uninstall risf
```

### ITSF

```bash
helm uninstall itsf
```
