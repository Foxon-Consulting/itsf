# ITSF / RISF - Plateforme Kubernetes Locale

[![integration](https://github.com/Foxon-Consulting/itsf/actions/workflows/standard.yml/badge.svg)](https://github.com/Foxon-Consulting/itsf/actions/workflows/standard.yml)

## TL;DR - Démarrage rapide

**Prérequis minimum :**
- Docker Desktop avec Kubernetes activé
- kubectl configuré
- Git Bash (Windows) ou Terminal (Linux/macOS)
- PowerShell avec droits administrateur (Windows uniquement)

**Installation rapide :**
```bash
# Cloner le dépôt
git clone <url-du-repo>
cd itsf

# Windows (avec Git Bash en administrateur)
./install.sh

# Linux/macOS
./install.sh
# Puis configurer manuellement /etc/hosts et importer le certificat
```

**Désinstallation :**
```bash
./uninstall.sh
```

**Accès aux sites :**
- https://hello-itsf.local.domain
- https://hello-risf.local.domain

---

Ce projet fournit une infrastructure Kubernetes complète pour déployer deux sites web sécurisés (`hello-itsf.local.domain` et `hello-risf.local.domain`) dans un environnement Kubernetes local.

## Table des matières

- [Prérequis](#prérequis)
- [Architecture](#architecture)
- [Installation](#installation)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [Structure du projet](#structure-du-projet)
- [Charts Helm](#charts-helm)
- [Gestion des volumes persistants](#gestion-des-volumes-persistants)
- [Développement](#développement)
- [Dépannage](#dépannage)

## Prérequis

- **Docker Desktop** avec Kubernetes activé (Windows/macOS) ou **Minikube** (Linux)
- **kubectl** correctement configuré
- **Git Bash** (pour Windows)
- **PowerShell** avec droits administrateur (pour Windows)
- **Helm** (optionnel mais recommandé)

## Architecture

L'architecture du projet comprend :

- Nginx Ingress Controller pour la gestion du trafic entrant
- Deux sites web (ITSF et RISF) avec leurs propres déploiements
- Un volume persistant pour le site ITSF
- Certificats TLS autosignés pour HTTPS
- Configuration DNS locale

## Installation

### Windows

1. Clonez ce dépôt et accédez au répertoire du projet
   ```bash
   git clone <url-du-repo>
   cd itsf
   ```

2. Exécutez le script d'installation avec des privilèges administrateur (Git Bash)
   ```bash
   ./install.sh
   ```
   Ce script :
   - Vérifie les droits administrateur
   - Configure le fichier hosts (ajoute des entrées DNS locales)
   - Installe les certificats CA dans le magasin de certificats Windows
   - Déploie l'Ingress Controller Nginx
   - Déploie les applications ITSF et RISF (vous pouvez choisir entre un déploiement standard ou via Helm)
   - Configure le volume persistant pour ITSF

### Linux / macOS

1. Clonez ce dépôt et accédez au répertoire du projet
   ```bash
   git clone <url-du-repo>
   cd itsf
   ```

2. Exécutez le script d'installation
   ```bash
   ./install.sh
   ```

3. Configurez manuellement votre fichier `/etc/hosts` pour ajouter les entrées suivantes :
   ```
   127.0.0.1 hello-itsf.local.domain www.hello-itsf.local.domain
   127.0.0.1 hello-risf.local.domain www.hello-risf.local.domain
   ```

4. Importez le certificat CA (`certs/ca.crt`) dans votre navigateur ou système

## Configuration

### Volumes persistants

Le site ITSF utilise un volume persistant pour stocker son contenu. Le contenu initial est disponible dans le répertoire `pv/` à la racine du projet. Le site RISF quant à lui n'utilise pas de volume persistant.

Pour créer ou recréer le volume persistant :

```bash
./scripts/create-pv.sh
```

> **Important** : Si vous devez recréer un PV existant, vous devez d'abord supprimer le PVC associé.
> Le projet fournit des scripts dédiés pour simplifier cette opération :
> ```bash
> # Pour supprimer un PV spécifique (supprime aussi le PVC associé)
> ./scripts/clean-pv.sh itsf-pv
>
> # Pour supprimer tous les PV du projet et leurs PVC
> ./scripts/clean-all-pv.sh
>
> # Puis recréer les volumes
> ./scripts/create-pv.sh
> ```
> Ces scripts gèrent correctement l'ordre de suppression et attendent que les ressources soient complètement supprimées avant de continuer.

### Certificats TLS

Les certificats sont autogénérés lors de l'installation. Si vous devez les recréer :

```bash
./scripts/create-ca.sh
./scripts/create-site-cert.sh hello-itsf.local.domain
./scripts/create-site-cert.sh hello-risf.local.domain
```

> **Important** : Si vous recréez le certificat CA, vous devez également le réinstaller dans votre système :
> - **Windows** : Exécutez `powershell.exe -ExecutionPolicy Bypass -File "scripts/install-ca-cert.ps1"` en tant qu'administrateur
> - **Linux/macOS** : Réimportez manuellement le certificat `certs/ca.crt` dans votre navigateur ou système

## Utilisation

Une fois l'installation terminée, vous pouvez accéder aux sites via :

- [https://hello-itsf.local.domain](https://hello-itsf.local.domain)
- [https://hello-risf.local.domain](https://hello-risf.local.domain)

### Commandes utiles

- Vérifier l'état des pods :
  ```bash
  kubectl get pods -A
  ```

- Vérifier les services et ingress :
  ```bash
  kubectl get services,ingress -A
  ```

- Installation ou réinstallation complète :
  ```bash
  ./install.sh
  ```

- Désinstallation complète :
  ```bash
  ./uninstall.sh
  ```

## Structure du projet

```
├── certs/                   # Certificats TLS
├── helm/                    # Charts Helm
│   ├── charts/              # Charts pour ITSF et RISF
│   │   ├── itsf/            # Chart Helm pour ITSF
│   │   └── risf/            # Chart Helm pour RISF
├── itsf/                    # Application ITSF
│   ├── k8s/                 # Manifestes Kubernetes pour ITSF
│   ├── Dockerfile           # Image Docker pour ITSF
│   └── deploy.sh            # Script de déploiement pour ITSF
├── risf/                    # Application RISF
│   ├── k8s/                 # Manifestes Kubernetes pour RISF
│   ├── Dockerfile           # Image Docker pour RISF
│   └── deploy.sh            # Script de déploiement pour RISF
├── pv/                      # Contenu des volumes persistants
├── scripts/                 # Scripts utilitaires
│   ├── common-preinstall.sh # Préparation de l'environnement
│   ├── common-postinstall.sh # Finalisation de l'installation
│   ├── common-preuninstall.sh # Préparation de la désinstallation
│   ├── common-postuninstall.sh # Finalisation de la désinstallation
│   ├── standard/            # Scripts d'installation/désinstallation standard
│   ├── helm/                # Scripts d'installation/désinstallation Helm
│   ├── create-pv.sh         # Création des volumes persistants
│   ├── clean-pv.sh          # Suppression d'un volume persistant
│   ├── clean-all-pv.sh      # Suppression de tous les volumes persistants
│   ├── install-ingress-controller.sh # Installation de l'Ingress Controller
│   ├── create-ca.sh         # Création du certificat CA
│   ├── create-site-cert.sh  # Création de certificats pour les sites
│   ├── create-pki.sh        # Utilitaires pour la création de certificats
│   ├── install-ca-cert.ps1  # Installation des certificats (Windows)
│   ├── install-hosts.ps1    # Configuration du fichier hosts (Windows)
│   ├── uninstall-hosts.ps1  # Nettoyage du fichier hosts (Windows)
│   └── uninstall-ca-cert.ps1 # Suppression des certificats (Windows)
├── .github/                 # Configuration GitHub
├── .githooks/               # Hooks Git pour le développement
├── install.sh               # Script principal d'installation
└── uninstall.sh             # Script principal de désinstallation
```

## Charts Helm

Le projet inclut des charts Helm pour faciliter le déploiement des applications ITSF et RISF. Ces charts sont situés dans le répertoire `helm/charts/`.

### Structure des charts Helm

```
helm/
├── charts/
│   ├── itsf/               # Chart pour ITSF
│   │   ├── templates/      # Templates Kubernetes
│   │   ├── Chart.yaml      # Métadonnées du chart
│   │   └── values.yaml     # Valeurs par défaut
│   └── risf/               # Chart pour RISF
│       ├── templates/      # Templates Kubernetes
│       ├── Chart.yaml      # Métadonnées du chart
│       └── values.yaml     # Valeurs par défaut
└── README.md               # Documentation des charts
```

### Déploiement avec Helm

Le script d'installation vous propose le choix entre un déploiement standard et un déploiement via Helm. Si vous choisissez Helm, les applications seront déployées dans leurs propres namespaces (`itsf` et `risf`).

Vous pouvez également déployer manuellement les applications avec Helm :

```bash
# Déploiement de RISF
helm upgrade --install risf ./helm/charts/risf --create-namespace

# Déploiement de ITSF
helm upgrade --install itsf ./helm/charts/itsf --create-namespace
```

Pour vérifier les déploiements Helm :

```bash
helm list -A
```

Pour désinstaller les déploiements Helm :

```bash
helm uninstall risf -n risf
helm uninstall itsf -n itsf
```

## Gestion des volumes persistants

Le volume persistant permet de stocker le contenu du site ITSF de manière persistante sur le système hôte. Le script `scripts/create-pv.sh` détecte automatiquement le système d'exploitation et configure le chemin correct pour le volume.

Le projet fournit plusieurs scripts pour la gestion du volume persistant :

- `create-pv.sh` : Crée le volume persistant avec le chemin approprié pour votre OS
- `clean-pv.sh` : Supprime un volume persistant spécifique et son PVC associé
  ```bash
  ./scripts/clean-pv.sh <nom-du-pv>  # Ex: ./scripts/clean-pv.sh itsf-pv
  ```
- `clean-all-pv.sh` : Supprime tous les volumes persistants du projet et leurs PVC

Ces scripts gèrent automatiquement les dépendances et les contraintes de suppression de Kubernetes.

## Développement

### Docker Compose pour le développement local

Pour un développement rapide sans Kubernetes, les applications ITSF et RISF peuvent être exécutées avec Docker Compose :

```bash
# Pour démarrer l'application ITSF
cd itsf
docker-compose up -d

# Pour démarrer l'application RISF
cd risf
docker-compose up -d
```

Les applications seront accessibles sur le port 80 :
- ITSF : http://hello-itsf.local.domain
- RISF : http://hello-risf.local.domain

> **Note** : Vous devez toujours configurer votre fichier hosts pour les domaines locaux.

Ces configurations Docker Compose sont particulièrement utiles pour le développement et les tests rapides sans avoir à configurer l'ensemble de l'infrastructure Kubernetes.

### Pre-commit

Ce projet utilise [pre-commit](https://pre-commit.com/) pour maintenir la qualité du code. Pour configurer les hooks pre-commit :

1. Installez pre-commit :
   ```bash
   pip install pre-commit
   ```

2. Installez les hooks Git :
   ```bash
   pre-commit install
   ```

Les hooks configurés dans `.pre-commit-config.yaml`
