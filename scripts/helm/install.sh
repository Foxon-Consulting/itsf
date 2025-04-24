#!/bin/bash
set -e

echo "====================================================================="
echo "  Installation avec Helm de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROJECT_DIR="$(cd "${PARENT_DIR}/.." && pwd)"

# Exécuter le script de préinstallation commun
echo "Exécution des opérations de préinstallation..."
"$PARENT_DIR/common-preinstall.sh"
echo ""

# Vérification si le namespace itsf existe déjà
if kubectl get namespace itsf &>/dev/null; then
    echo "Le namespace itsf existe déjà, suppression pour éviter les conflits avec Helm..."
    kubectl delete namespace itsf
    # Attendre que le namespace soit complètement supprimé
    echo "Attente de la suppression complète du namespace itsf..."
    while kubectl get namespace itsf &>/dev/null; do
        echo "En attente de la suppression du namespace itsf..."
        sleep 2
    done
    echo "Namespace itsf supprimé avec succès."
    # Attendre un peu plus pour s'assurer que toutes les ressources sont bien nettoyées
    echo "Attente supplémentaire pour s'assurer que les ressources sont bien libérées..."
    sleep 5
fi

# Vérification si le namespace risf existe déjà
if kubectl get namespace risf &>/dev/null; then
    echo "Le namespace risf existe déjà, suppression pour éviter les conflits avec Helm..."
    kubectl delete namespace risf
    # Attendre que le namespace soit complètement supprimé
    echo "Attente de la suppression complète du namespace risf..."
    while kubectl get namespace risf &>/dev/null; do
        echo "En attente de la suppression du namespace risf..."
        sleep 2
    done
    echo "Namespace risf supprimé avec succès."
    # Attendre un peu plus pour s'assurer que toutes les ressources sont bien nettoyées
    echo "Attente supplémentaire pour s'assurer que les ressources sont bien libérées..."
    sleep 5
fi

# Déploiement avec Helm
echo "Déploiement de RISF avec Helm..."
# Ne PAS créer manuellement le namespace, laisser Helm le faire
echo "Installation de RISF avec Helm (y compris la création du namespace)..."
helm upgrade --install risf "${PROJECT_DIR}/helm/charts/risf" --create-namespace

# Créer le secret TLS pour RISF
echo "Création du secret TLS pour RISF..."
RISF_CERT_DIR="${PROJECT_DIR}/certs/hello-risf.local.domain"
kubectl create secret tls tls-secret-hello-risf-local-domain \
    --cert="${RISF_CERT_DIR}/tls.crt" \
    --key="${RISF_CERT_DIR}/tls.key" \
    --namespace=risf \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Déploiement de ITSF avec Helm..."
# Ne PAS créer manuellement le namespace, laisser Helm le faire
echo "Installation de ITSF avec Helm (y compris la création du namespace)..."
helm upgrade --install itsf "${PROJECT_DIR}/helm/charts/itsf" --create-namespace

# Créer le secret TLS pour ITSF
echo "Création du secret TLS pour ITSF..."
ITSF_CERT_DIR="${PROJECT_DIR}/certs/hello-itsf.local.domain"
kubectl create secret tls tls-secret-hello-itsf-local-domain \
    --cert="${ITSF_CERT_DIR}/tls.crt" \
    --key="${ITSF_CERT_DIR}/tls.key" \
    --namespace=itsf \
    --dry-run=client -o yaml | kubectl apply -f -

echo "Les déploiements Helm sont terminés."

# Exécuter le script de post-installation
echo "Exécution des opérations de post-installation..."
"$PARENT_DIR/common-postinstall.sh"
