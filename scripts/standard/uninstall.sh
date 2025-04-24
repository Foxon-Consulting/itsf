#!/bin/bash
set -e

echo "====================================================================="
echo "  Désinstallation standard de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${PARENT_DIR}/.." && pwd)"

# Exécuter le script de pré-désinstallation
echo "Exécution des opérations de pré-désinstallation..."
"$PARENT_DIR/common-preuninstall.sh"
echo ""

# Désinstallation des ressources Kubernetes
echo "Suppression des ressources Kubernetes..."
echo "----------------------------------------------------------------------"

# Désinstallation dans l'ordre inverse des installations (RISF d'abord, puis ITSF)
echo "1. Suppression des ressources pour RISF..."
kubectl delete ingress -n itsf risf-ingress --ignore-not-found=true
kubectl delete service -n itsf risf-service --ignore-not-found=true
kubectl delete deployment -n itsf risf-deployment --ignore-not-found=true
kubectl delete secret -n itsf --all --ignore-not-found=true
kubectl delete serviceaccount -n itsf restricted-service-account --ignore-not-found=true
kubectl delete role -n itsf minimal-permissions --ignore-not-found=true
kubectl delete rolebinding -n itsf restricted-binding --ignore-not-found=true

echo "2. Suppression des ressources pour ITSF..."
kubectl delete ingress -n itsf itsf-ingress --ignore-not-found=true
kubectl delete service -n itsf itsf-service --ignore-not-found=true
kubectl delete deployment -n itsf itsf-deployment --ignore-not-found=true
kubectl delete pvc -n itsf itsf-pvc --ignore-not-found=true
kubectl delete secret -n itsf --all --ignore-not-found=true
kubectl delete serviceaccount -n itsf restricted-service-account --ignore-not-found=true
kubectl delete role -n itsf minimal-permissions --ignore-not-found=true
kubectl delete rolebinding -n itsf restricted-binding --ignore-not-found=true

# Suppression des namespaces - en dernier car ils ont été créés en premier
echo "Suppression des namespaces..."
kubectl delete namespace itsf --ignore-not-found=true

# Suppression du contrôleur Ingress NGINX (installé en premier, désinstallé en dernier)
echo "Suppression du contrôleur Ingress NGINX..."
echo "----------------------------------------------------------------------"
kubectl delete namespace ingress-nginx --ignore-not-found=true
echo "Contrôleur Ingress NGINX supprimé."
echo ""

# Exécuter le script de post-désinstallation
echo "Exécution des opérations de post-désinstallation..."
"$PARENT_DIR/common-postuninstall.sh"
