#!/bin/bash
set -e

echo "====================================================================="
echo "  Préparation de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Rendre les scripts exécutables
echo "Configuration des permissions sur les scripts..."
chmod +x "$SCRIPT_DIR/"*.sh
chmod +x "$ROOT_DIR/itsf/deploy.sh"
chmod +x "$ROOT_DIR/risf/deploy.sh"
echo "Permissions configurées avec succès."

# Vérification des certificats
echo "Vérification des certificats TLS..."
echo "----------------------------------------------------------------------"
# Vérifier si le certificat CA existe déjà
if [ ! -f "$ROOT_DIR/certs/ca.crt" ]; then
    echo "Création du certificat CA..."
    "$SCRIPT_DIR/create-ca.sh"
    echo "Création du certificat pour ITSF..."
    "$SCRIPT_DIR/create-site-cert.sh" hello-itsf.local.domain
    echo "Création du certificat pour RISF..."
    "$SCRIPT_DIR/create-site-cert.sh" hello-risf.local.domain
    echo "Certificats créés avec succès."
else
    echo "Les certificats existent déjà."
fi
echo ""

# Installation du contrôleur Ingress NGINX
echo "Installation du contrôleur Ingress NGINX..."
echo "----------------------------------------------------------------------"
"$SCRIPT_DIR/install-ingress-controller.sh"
echo ""

# Construction des images Docker
echo "Construction des images Docker..."
# Construction de l'image RISF
echo "Construction de l'image RISF..."
cd "$ROOT_DIR/risf"
docker build -t risf:latest .

# Construction de l'image ITSF
echo "Construction de l'image ITSF..."
cd "$ROOT_DIR/itsf"
docker build -t itsf:latest .
echo "Images Docker construites avec succès."
echo ""

# Création du volume persistant pour ITSF
echo "Configuration du volume persistant (PV) pour ITSF..."
"$SCRIPT_DIR/create-pv.sh"
echo ""

# Retour au répertoire des scripts
cd "$SCRIPT_DIR"
