#!/bin/bash
set -e

echo "====================================================================="
echo "  Préparation de la désinstallation de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Fonction pour forcer la suppression d'un PVC en supprimant d'abord les finalizers
force_delete_pvc() {
    local namespace=$1
    local pvc_name=$2

    echo "Suppression forcée du PVC $pvc_name dans le namespace $namespace..."

    # Suppression des finalizers du PVC
    echo "Suppression des finalizers du PVC $pvc_name..."
    kubectl patch pvc "$pvc_name" -n "$namespace" -p '{"metadata":{"finalizers":null}}' || true

    # Suppression du PVC avec --force
    echo "Suppression du PVC $pvc_name..."
    kubectl delete pvc "$pvc_name" -n "$namespace" --force --grace-period=0 || true
}

# Nettoyage des PVCs bloqués avant de continuer
echo "Vérification des PVCs potentiellement bloqués..."
echo "----------------------------------------------------------------------"
# Vérifier si le PVC itsf-pvc existe dans le namespace itsf
if kubectl get pvc itsf-pvc -n itsf &> /dev/null; then
    echo "PVC itsf-pvc trouvé, suppression forcée pour éviter les blocages..."
    force_delete_pvc "itsf" "itsf-pvc"
fi
echo ""

# Vérification des namespaces
echo "Vérification des namespaces..."
echo "----------------------------------------------------------------------"
# Vérifier quels namespaces existent
ITSF_EXISTS=$(kubectl get namespace itsf --ignore-not-found=true 2>/dev/null | grep -c itsf || echo "0")
RISF_EXISTS=$(kubectl get namespace risf --ignore-not-found=true 2>/dev/null | grep -c risf || echo "0")
INGRESS_EXISTS=$(kubectl get namespace ingress-nginx --ignore-not-found=true 2>/dev/null | grep -c ingress-nginx || echo "0")

if [ "$ITSF_EXISTS" -gt 0 ]; then
    echo "Namespace itsf trouvé, sera supprimé pendant le processus de désinstallation."
else
    echo "Namespace itsf non trouvé."
fi

if [ "$RISF_EXISTS" -gt 0 ]; then
    echo "Namespace risf trouvé, sera supprimé pendant le processus de désinstallation."
else
    echo "Namespace risf non trouvé."
fi

if [ "$INGRESS_EXISTS" -gt 0 ]; then
    echo "Namespace ingress-nginx trouvé, sera supprimé pendant le processus de désinstallation."
else
    echo "Namespace ingress-nginx non trouvé."
fi
echo ""

# Détection de la méthode d'installation
echo "Détection de la méthode d'installation précédente..."
echo "----------------------------------------------------------------------"
HELM_INSTALLED_ITSF=0
HELM_INSTALLED_RISF=0

# Vérifier si helm est installé
if command -v helm >/dev/null 2>&1; then
    # Capturer le résultat de helm list seulement si helm est disponible
    HELM_OUTPUT_ITSF=$(helm list -n itsf -q 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$HELM_OUTPUT_ITSF" ]; then
        HELM_INSTALLED_ITSF=1
    fi

    HELM_OUTPUT_RISF=$(helm list -n risf -q 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$HELM_OUTPUT_RISF" ]; then
        HELM_INSTALLED_RISF=1
    fi
fi

if [ "$HELM_INSTALLED_ITSF" -eq 1 ] || [ "$HELM_INSTALLED_RISF" -eq 1 ]; then
    echo "Installation avec Helm détectée."
else
    echo "Installation standard détectée ou aucune installation trouvée."
fi
echo ""

echo "====================================================================="
echo "  Préparation de la désinstallation terminée"
echo "====================================================================="
echo ""
