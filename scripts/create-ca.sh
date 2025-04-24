#!/bin/bash
set -e

# Fonction pour convertir les chemins Windows en chemins Unix
winpath() {
  echo "/$1" | sed 's/\\/\//g' | sed 's/://'
}

# Créer le répertoire pour les certificats
mkdir -p certs

# Générer la clé privée CA
openssl genrsa -out certs/ca.key 2048

# Générer le certificat CA
# Windows git-bash nécessite un format spécial pour -subj
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  # Format pour Windows
  openssl req -x509 -new -nodes -key certs/ca.key -sha256 -days 365 -out certs/ca.crt -subj "//CN=kubernetes-ca"
else
  # Format pour Unix/Linux/Mac
  openssl req -x509 -new -nodes -key certs/ca.key -sha256 -days 365 -out certs/ca.crt -subj "//CN=kubernetes-ca"
fi

echo "Autorité de certification (CA) générée avec succès dans le répertoire certs/"
