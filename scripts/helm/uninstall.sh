#!/bin/bash
set -e

echo "====================================================================="
echo "  Désinstallation avec Helm de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="$(cd "${PARENT_DIR}/.." && pwd)"

# Exécuter le script de pré-désinstallation
echo "Exécution des opérations de pré-désinstallation..."
"$PARENT_DIR/common-preuninstall.sh"
echo ""

# Désinstallation avec Helm (dans l'ordre inverse de l'installation)
echo "Désinstallation des déploiements Helm..."
echo "----------------------------------------------------------------------"

# Désinstallation dans l'ordre inverse de l'installation (ITSF d'abord, puis RISF)
# Déploiement ITSF
echo "Suppression du déploiement ITSF avec Helm..."
helm uninstall itsf -n itsf --ignore-not-found=true

# Déploiement RISF
echo "Suppression du déploiement RISF avec Helm..."
helm uninstall risf -n risf --ignore-not-found=true

# Suppression des namespaces - en dernier
echo "Suppression des namespaces..."
kubectl delete namespace itsf --ignore-not-found=true
kubectl delete namespace risf --ignore-not-found=true

echo "Désinstallation des déploiements Helm terminée."
echo ""

# Suppression du contrôleur Ingress NGINX (installé en premier, désinstallé en dernier)
echo "Suppression du contrôleur Ingress NGINX..."
echo "----------------------------------------------------------------------"
kubectl delete namespace ingress-nginx --ignore-not-found=true
echo "Contrôleur Ingress NGINX supprimé."
echo ""

# Exécuter le script de post-désinstallation
echo "Exécution des opérations de post-désinstallation..."
"$PARENT_DIR/common-postuninstall.sh"
