#!/bin/bash
set -e

# Vérifier si un domaine a été fourni en argument
if [ -z "$1" ]; then
  echo "Erreur: Veuillez spécifier un nom de domaine comme argument."
  echo "Usage: $0 domain.local"
  exit 1
fi

DOMAIN=$1

# Fonction pour convertir les chemins Windows en chemins Unix
winpath() {
  echo "/$1" | sed 's/\\/\//g' | sed 's/://'
}

# Créer le répertoire pour les certificats du domaine
mkdir -p "certs/$DOMAIN"

# Générer une clé privée pour le domaine
openssl genrsa -out "certs/$DOMAIN/tls.key" 2048

# Créer un fichier de configuration temporaire pour OpenSSL
CONFIG_FILE="certs/$DOMAIN/openssl.cnf"
cat > "$CONFIG_FILE" <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = www.$DOMAIN
DNS.3 = *.$DOMAIN
EOF

# Créer une demande de signature de certificat (CSR)
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  # Format pour Windows
  openssl req -new -key "certs/$DOMAIN/tls.key" -out "certs/$DOMAIN/tls.csr" -subj "//CN=$DOMAIN" -config "$CONFIG_FILE"
else
  # Format pour Unix/Linux/Mac
  openssl req -new -key "certs/$DOMAIN/tls.key" -out "certs/$DOMAIN/tls.csr" -subj "/CN=$DOMAIN" -config "$CONFIG_FILE"
fi

# Signer la CSR avec l'autorité de certification
openssl x509 -req -in "certs/$DOMAIN/tls.csr" -CA certs/ca.crt -CAkey certs/ca.key \
  -CAcreateserial -out "certs/$DOMAIN/tls.crt" -days 365 -sha256 \
  -extensions v3_req -extfile "$CONFIG_FILE"

# Supprimer le fichier de configuration temporaire
rm -f "$CONFIG_FILE"

echo "Certificat pour $DOMAIN généré avec succès !"
echo "  - Clé privée: certs/$DOMAIN/tls.key"
echo "  - Certificat: certs/$DOMAIN/tls.crt"
