#!/bin/bash
set -e

# Fonction pour convertir les chemins Windows en chemins Unix
winpath() {
  echo "/$1" | sed 's/\\/\//g' | sed 's/://'
}

# Créer le répertoire pour les certificats
mkdir -p certs

# Vérifier si le CA existe déjà
if [ -f certs/ca.key ] && [ -f certs/ca.crt ]; then
  echo "L'autorité de certification (CA) existe déjà, pas besoin de la régénérer."
else
  # Générer l'autorité de certification (CA)
  echo "Génération de l'autorité de certification..."
  bash ./scripts/create-ca.sh
fi

# Liste des domaines pour lesquels générer des certificats
DOMAINS=("hello-itsf.local.domain" "hello-risf.local.domain")

# Générer des certificats pour chaque domaine
for domain in "${DOMAINS[@]}"; do
  echo "Génération du certificat pour $domain..."
  bash ./scripts/create-site-cert.sh "$domain"
done

echo "Infrastructure PKI générée avec succès!"
echo "Pour utiliser ces certificats avec Kubernetes, créez des secrets TLS correspondants."
