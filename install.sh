#!/bin/bash
set -e

echo "====================================================================="
echo "  Installation complète de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Vérification des droits d'administrateur sous Windows
check_admin_windows() {
  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "Vérification des privilèges administrateur sur Windows..."
    # Utiliser PowerShell pour vérifier les privilèges admin
    IS_ADMIN=$(powershell.exe -Command "([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)" | tr -d '\r\n')

    if [ "$IS_ADMIN" != "True" ]; then
      echo "ERREUR: Ce script doit être exécuté avec des privilèges administrateur sur Windows."
      echo "Veuillez fermer cette fenêtre et exécuter Git Bash en tant qu'administrateur."
      exit 1
    else
      echo "Droits administrateur confirmés."
    fi
  fi
}

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Rendre les scripts exécutables
echo "Configuration des permissions sur les scripts..."
chmod +x "$SCRIPT_DIR/scripts/"*.sh
chmod +x "$SCRIPT_DIR/scripts/helm/"*.sh
chmod +x "$SCRIPT_DIR/scripts/standard/"*.sh
chmod +x "$SCRIPT_DIR/itsf/deploy.sh"
chmod +x "$SCRIPT_DIR/risf/deploy.sh"
echo "Permissions configurées avec succès."

# Vérifier les privilèges administrateur sur Windows
check_admin_windows

# Configuration du DNS local (Windows uniquement)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "Configuration du DNS local et des certificats (Windows)..."
    echo "----------------------------------------------------------------------"

    echo "Mise à jour du fichier hosts..."
    powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/scripts/install-hosts.ps1" FromBash

    echo "Installation du certificat CA dans le magasin de certificats Windows..."
    powershell.exe -ExecutionPolicy Bypass -File "$SCRIPT_DIR/scripts/install-ca-cert.ps1" FromBash

    echo "Configuration locale terminée."
    echo ""
fi

echo "Installation de l'environnement..."
echo "----------------------------------------------------------------------"
read -p "Souhaitez-vous utiliser Helm pour le déploiement? (o/n) [n]: " use_helm
use_helm=${use_helm:-n}

if [[ "$use_helm" == "o" || "$use_helm" == "O" ]]; then
    echo "Déploiement avec Helm..."
    "$SCRIPT_DIR/scripts/helm/install.sh"
else
    echo "Déploiement standard..."
    "$SCRIPT_DIR/scripts/standard/install.sh"
fi
