#!/bin/bash
set -e

echo "====================================================================="
echo "  Désinstallation de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Rendre les scripts exécutables
echo "Configuration des permissions sur les scripts..."
chmod +x "$SCRIPT_DIR/scripts/"*.sh
chmod +x "$SCRIPT_DIR/scripts/helm/"*.sh
chmod +x "$SCRIPT_DIR/scripts/standard/"*.sh
echo "Permissions configurées avec succès."

# Détection de la méthode d'installation précédente
echo "Détection de la méthode d'installation précédente..."
# Utiliser des variables numériques avec une gestion d'erreur robuste
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

echo "Désinstallation de l'environnement..."
echo "----------------------------------------------------------------------"

if [ "$HELM_INSTALLED_ITSF" -eq 1 ] || [ "$HELM_INSTALLED_RISF" -eq 1 ]; then
    echo "Déploiement précédent avec Helm détecté, désinstallation avec Helm..."
    "$SCRIPT_DIR/scripts/helm/uninstall.sh"
else
    echo "Déploiement standard détecté ou aucun déploiement, désinstallation standard..."
    "$SCRIPT_DIR/scripts/standard/uninstall.sh"
fi

echo "====================================================================="
echo "  Désinstallation terminée!"
echo "====================================================================="
echo ""
echo "L'environnement ITSF/RISF a été supprimé."
echo "Les images Docker locales restent intactes et peuvent être supprimées manuellement si nécessaire."
echo "====================================================================="
