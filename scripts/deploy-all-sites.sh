#!/bin/bash
set -e

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Déploiement de tous les sites..."

echo "1. Déploiement du site ITSF (hello-itsf.local.domain)"
cd "$ROOT_DIR/itsf"
if [ ! -f "deploy.sh" ]; then
  echo "ERREUR: Le script deploy.sh est introuvable dans le répertoire $(pwd)"
  exit 1
fi
chmod +x deploy.sh
bash ./deploy.sh
cd "$SCRIPT_DIR"

echo "2. Déploiement du site RISF (hello-risf.local.domain)"
cd "$ROOT_DIR/risf"
if [ ! -f "deploy.sh" ]; then
  echo "ERREUR: Le script deploy.sh est introuvable dans le répertoire $(pwd)"
  exit 1
fi
chmod +x deploy.sh
bash ./deploy.sh
cd "$SCRIPT_DIR"

echo "3. Vérification des ingress déployés"
kubectl get ingress -n itsf

echo "Déploiement de tous les sites terminé!"
echo "Les sites suivants sont accessibles via HTTPS:"
echo "- https://hello-itsf.local.domain"
echo "- https://www.hello-itsf.local.domain"
echo "- https://hello-risf.local.domain"
echo "- https://www.hello-risf.local.domain"
echo "N'oubliez pas de configurer votre DNS pour pointer vers l'adresse IP des Ingress."
