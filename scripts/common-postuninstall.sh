#!/bin/bash
set -e

echo "====================================================================="
echo "  Finalisation de la désinstallation de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Nettoyage des volumes persistants (installés en dernier, désinstallés en premier)
echo "Nettoyage final des volumes persistants..."
echo "----------------------------------------------------------------------"
CLEAN_PV_SCRIPT="$SCRIPT_DIR/clean-pv.sh"
if [ -f "$CLEAN_PV_SCRIPT" ]; then
    echo "Utilisation du script clean-pv.sh pour nettoyer le volume persistant itsf-pv..."
    # Définir un timeout de 30 secondes pour le script clean-pv.sh
    timeout 30s "$CLEAN_PV_SCRIPT" itsf-pv --force || {
        echo "Le script clean-pv.sh a pris trop de temps, suppression forcée via kubectl..."
        kubectl patch pv itsf-pv -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
        kubectl delete pv itsf-pv --force --grace-period=0 --ignore-not-found=true
    }
else
    echo "Script clean-pv.sh non trouvé, utilisation de kubectl pour supprimer le PV..."
    kubectl patch pv itsf-pv -p '{"metadata":{"finalizers":null}}' 2>/dev/null || true
    kubectl delete pv itsf-pv --force --grace-period=0 --ignore-not-found=true
fi
echo "Volumes persistants supprimés."
echo ""

# Vérifier s'il reste des namespaces
echo "Vérification des namespaces restants..."
echo "----------------------------------------------------------------------"
# Initialiser les variables
ITSF_EXISTS=0
RISF_EXISTS=0
INGRESS_EXISTS=0

# Vérifier l'existence des namespaces de manière plus robuste
if kubectl get namespace itsf --ignore-not-found=true 2>/dev/null | grep -q "itsf"; then
    ITSF_EXISTS=1
fi
if kubectl get namespace risf --ignore-not-found=true 2>/dev/null | grep -q "risf"; then
    RISF_EXISTS=1
fi
if kubectl get namespace ingress-nginx --ignore-not-found=true 2>/dev/null | grep -q "ingress-nginx"; then
    INGRESS_EXISTS=1
fi

if [ $ITSF_EXISTS -eq 1 ] || [ $RISF_EXISTS -eq 1 ] || [ $INGRESS_EXISTS -eq 1 ]; then
    echo "AVERTISSEMENT: Certains namespaces n'ont pas été supprimés correctement."

    if [ $ITSF_EXISTS -eq 1 ]; then
        echo "Le namespace itsf existe toujours. Tentative de suppression forcée..."
        kubectl delete namespace itsf --force --grace-period=0 --ignore-not-found=true
    fi

    if [ $RISF_EXISTS -eq 1 ]; then
        echo "Le namespace risf existe toujours. Tentative de suppression forcée..."
        kubectl delete namespace risf --force --grace-period=0 --ignore-not-found=true
    fi

    if [ $INGRESS_EXISTS -eq 1 ]; then
        echo "Le namespace ingress-nginx existe toujours. Tentative de suppression forcée..."
        kubectl delete namespace ingress-nginx --force --grace-period=0 --ignore-not-found=true
    fi
else
    echo "Tous les namespaces ont été supprimés correctement."
fi
echo ""

# Nettoyage du système local (Windows uniquement)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "Nettoyage des entrées DNS locales (Windows)..."
    echo "----------------------------------------------------------------------"

    # Vérifier si le script existe
    if [ -f "$SCRIPT_DIR/uninstall-hosts.ps1" ]; then
        echo "Suppression des entrées DNS dans le fichier hosts..."
        powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/uninstall-hosts.ps1" FromBash || true
    else
        echo "Script uninstall-hosts.ps1 non trouvé."
        echo "Pour nettoyer manuellement, supprimez les entrées *.local.domain de C:\Windows\System32\drivers\etc\hosts"
    fi

    # Vérifier si le script de désinstallation du certificat existe
    if [ -f "$SCRIPT_DIR/uninstall-ca-cert.ps1" ]; then
        echo "Suppression du certificat CA du magasin de certificats Windows..."
        powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/uninstall-ca-cert.ps1" FromBash || true
    else
        echo "Script uninstall-ca-cert.ps1 non trouvé."
        echo "Pour supprimer manuellement le certificat, utilisez le gestionnaire de certificats Windows."
    fi
else
    echo "Sur les systèmes Linux/macOS, pensez à supprimer les entrées *.local.domain de /etc/hosts"
    echo "et à supprimer le certificat CA de votre navigateur/système si nécessaire."
fi
echo ""

# Nettoyage des images Docker locales (facultatif)
echo "Note: Les images Docker locales ne sont pas automatiquement supprimées."
echo "Pour les supprimer manuellement, utilisez: docker rmi risf:latest itsf:latest"
echo ""

echo "====================================================================="
echo "  Désinstallation terminée! L'environnement a été nettoyé."
echo "====================================================================="
