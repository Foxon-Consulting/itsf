#!/bin/bash
set -e

echo "====================================================================="
echo "  Installation standard (sans Helm) de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT_DIR="$(cd "${PARENT_DIR}/.." && pwd)"

# Exécuter le script de préinstallation commun
echo "Exécution des opérations de préinstallation..."
"$PARENT_DIR/common-preinstall.sh"
echo ""

echo "Déploiement des applications..."
echo "----------------------------------------------------------------------"

echo "1. Déploiement du site ITSF (hello-itsf.local.domain)"
cd "$ROOT_DIR/itsf"
if [ ! -f "deploy.sh" ]; then
  echo "ERREUR: Le script deploy.sh est introuvable dans le répertoire $(pwd)"
  exit 1
fi
# On ne construit plus l'image Docker ici car c'est fait dans common-preinstall.sh
# On ne crée plus les certificats ici car c'est fait dans common-preinstall.sh
# On ne crée plus le PV ici car c'est fait dans common-preinstall.sh

# Déployer les ressources Kubernetes seulement
kubectl apply -f "$ROOT_DIR/itsf/k8s/namespace.yaml"
kubectl apply -f "$ROOT_DIR/itsf/k8s/service-account.yaml"
kubectl apply -f "$ROOT_DIR/itsf/k8s/pvc.yaml"
kubectl apply -f "$ROOT_DIR/itsf/k8s/deployment.yaml"
kubectl apply -f "$ROOT_DIR/itsf/k8s/service.yaml"

# Créer le secret TLS pour ITSF
echo "Création du secret TLS pour ITSF..."
DOMAIN="hello-itsf.local.domain"
DOMAIN_SLUG=$(echo $DOMAIN | tr '.' '-')
CERT_DIR="$ROOT_DIR/certs/$DOMAIN"
SECRET_FILE="$ROOT_DIR/itsf/k8s/tls-secret-$DOMAIN_SLUG.yaml"

# Copier le template
cp "$ROOT_DIR/itsf/k8s/tls-secret.yaml" "$SECRET_FILE"

# Générer le contenu encodé en base64
TLS_CRT=$(cat "$CERT_DIR/tls.crt" | base64 -w 0 2>/dev/null || cat "$CERT_DIR/tls.crt" | base64 -b 0)
TLS_KEY=$(cat "$CERT_DIR/tls.key" | base64 -w 0 2>/dev/null || cat "$CERT_DIR/tls.key" | base64 -b 0)

# Remplacer les valeurs dans le fichier
sed -i "s|name: tls-secret|name: tls-secret-$DOMAIN_SLUG|g" "$SECRET_FILE"

# Créer des fichiers temporaires pour les certificats encodés
TEMP_DIR="$(mktemp -d)"
TEMP_CRT="$TEMP_DIR/temp_crt.txt"
TEMP_KEY="$TEMP_DIR/temp_key.txt"

echo "$TLS_CRT" > "$TEMP_CRT"
echo "$TLS_KEY" > "$TEMP_KEY"

# Remplacer les contenus des fichiers
sed -i "s|tls.crt: \"\"|tls.crt: $(cat "$TEMP_CRT")|g" "$SECRET_FILE"
sed -i "s|tls.key: \"\"|tls.key: $(cat "$TEMP_KEY")|g" "$SECRET_FILE"

# Appliquer le secret TLS
kubectl apply -f "$SECRET_FILE"

# Appliquer l'ingress
kubectl apply -f "$ROOT_DIR/itsf/k8s/ingress.yaml"

# Supprimer le fichier secret temporaire
rm -f "$SECRET_FILE"
rm -rf "$TEMP_DIR"

cd "$SCRIPT_DIR"

echo "2. Déploiement du site RISF (hello-risf.local.domain)"
cd "$ROOT_DIR/risf"
if [ ! -f "deploy.sh" ]; then
  echo "ERREUR: Le script deploy.sh est introuvable dans le répertoire $(pwd)"
  exit 1
fi
# On ne construit plus l'image Docker ici car c'est fait dans common-preinstall.sh
# On ne crée plus les certificats ici car c'est fait dans common-preinstall.sh

# Déployer les ressources Kubernetes seulement
kubectl apply -f "$ROOT_DIR/risf/k8s/namespace.yaml"
kubectl apply -f "$ROOT_DIR/risf/k8s/service-account.yaml"
kubectl apply -f "$ROOT_DIR/risf/k8s/deployment.yaml"
kubectl apply -f "$ROOT_DIR/risf/k8s/service.yaml"

# Créer le secret TLS pour RISF
echo "Création du secret TLS pour RISF..."
DOMAIN="hello-risf.local.domain"
DOMAIN_SLUG=$(echo $DOMAIN | tr '.' '-')
CERT_DIR="$ROOT_DIR/certs/$DOMAIN"
SECRET_FILE="$ROOT_DIR/risf/k8s/tls-secret-$DOMAIN_SLUG.yaml"

# Copier le template
cp "$ROOT_DIR/risf/k8s/tls-secret.yaml" "$SECRET_FILE"

# Générer le contenu encodé en base64
TLS_CRT=$(cat "$CERT_DIR/tls.crt" | base64 -w 0 2>/dev/null || cat "$CERT_DIR/tls.crt" | base64 -b 0)
TLS_KEY=$(cat "$CERT_DIR/tls.key" | base64 -w 0 2>/dev/null || cat "$CERT_DIR/tls.key" | base64 -b 0)

# Remplacer les valeurs dans le fichier
sed -i "s|name: tls-secret|name: tls-secret-$DOMAIN_SLUG|g" "$SECRET_FILE"

# Créer des fichiers temporaires pour les certificats encodés
TEMP_DIR="$(mktemp -d)"
TEMP_CRT="$TEMP_DIR/temp_crt.txt"
TEMP_KEY="$TEMP_DIR/temp_key.txt"

echo "$TLS_CRT" > "$TEMP_CRT"
echo "$TLS_KEY" > "$TEMP_KEY"

# Remplacer les contenus des fichiers
sed -i "s|tls.crt: \"\"|tls.crt: $(cat "$TEMP_CRT")|g" "$SECRET_FILE"
sed -i "s|tls.key: \"\"|tls.key: $(cat "$TEMP_KEY")|g" "$SECRET_FILE"

# Appliquer le secret TLS
kubectl apply -f "$SECRET_FILE"

# Appliquer l'ingress
kubectl apply -f "$ROOT_DIR/risf/k8s/ingress.yaml"

# Supprimer le fichier secret temporaire
rm -f "$SECRET_FILE"
rm -rf "$TEMP_DIR"

cd "$SCRIPT_DIR"

# Exécuter le script de post-installation
echo "Exécution des opérations de post-installation..."
"$PARENT_DIR/common-postinstall.sh"
