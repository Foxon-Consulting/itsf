#!/bin/bash
set -e

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"
CERTS_DIR="$ROOT_DIR/certs"

# Vérifier que les scripts existent
if [ ! -d "$SCRIPTS_DIR" ]; then
  echo "Erreur: Le répertoire scripts ($SCRIPTS_DIR) n'existe pas"
  exit 1
fi

if [ ! -f "$SCRIPTS_DIR/create-ca.sh" ]; then
  echo "Erreur: Le script create-ca.sh est introuvable dans $SCRIPTS_DIR"
  exit 1
fi

if [ ! -f "$SCRIPTS_DIR/create-site-cert.sh" ]; then
  echo "Erreur: Le script create-site-cert.sh est introuvable dans $SCRIPTS_DIR"
  exit 1
fi

# Fonction pour convertir les chemins Windows en chemins Unix
winpath() {
  echo "/$1" | sed 's/\\/\//g' | sed 's/://'
}

# Définition des variables
DOMAIN="hello-risf.local.domain"
DOMAIN_SLUG=$(echo $DOMAIN | tr '.' '-')
CERT_DIR="$CERTS_DIR/$DOMAIN"
IMAGE_NAME="risf"
IMAGE_TAG="latest"

echo "Déploiement du site $DOMAIN..."
echo "Répertoire racine: $ROOT_DIR"
echo "Répertoire scripts: $SCRIPTS_DIR"
echo "Répertoire certificats: $CERTS_DIR"

echo "1. Vérification des certificats..."
# Vérifier si le certificat existe déjà
mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_DIR/tls.crt" ] || [ ! -f "$CERT_DIR/tls.key" ]; then
  echo "Génération des certificats PKI..."
  # S'assurer que les scripts sont exécutables
  chmod +x "$SCRIPTS_DIR/create-ca.sh"
  chmod +x "$SCRIPTS_DIR/create-site-cert.sh"
  chmod +x "$SCRIPTS_DIR/create-pki.sh" 2>/dev/null || true

  # Vérifier si le CA existe déjà
  mkdir -p "$CERTS_DIR"
  if [ ! -f "$CERTS_DIR/ca.key" ] || [ ! -f "$CERTS_DIR/ca.crt" ]; then
    echo "Génération de l'autorité de certification..."
    # Exécuter le script depuis le répertoire racine
    (cd "$ROOT_DIR" && bash "$SCRIPTS_DIR/create-ca.sh")
  fi

  # Générer le certificat pour le domaine
  echo "Génération du certificat pour $DOMAIN..."
  # Exécuter le script depuis le répertoire racine
  (cd "$ROOT_DIR" && bash "$SCRIPTS_DIR/create-site-cert.sh" "$DOMAIN")
fi

echo "2. Construction de l'image Docker..."
# Vérifier que docker est disponible
if ! command -v docker &> /dev/null; then
  echo "Erreur: Docker n'est pas installé ou n'est pas dans le PATH"
  exit 1
fi

# Construction de l'image
echo "Construction de l'image $IMAGE_NAME:$IMAGE_TAG..."
(cd "$SCRIPT_DIR" && docker build -t "$IMAGE_NAME:$IMAGE_TAG" .)

echo "3. Création du secret TLS avec les certificats..."
SECRET_FILE="$SCRIPT_DIR/k8s/tls-secret-$DOMAIN_SLUG.yaml"

# Copier le template
cp "$SCRIPT_DIR/k8s/tls-secret.yaml" "$SECRET_FILE"

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

# Supprimer les fichiers temporaires
rm -rf "$TEMP_DIR"

echo "4. Déploiement des ressources Kubernetes..."
# Créer d'abord le namespace
kubectl apply -f "$SCRIPT_DIR/k8s/namespace.yaml"

# Vérifier et supprimer les ressources existantes qui pourraient causer des conflits
echo "Vérification de l'existence d'Ingress conflictuels..."
if kubectl get ingress risf-ingress -n itsf &>/dev/null; then
  echo "Ingress existant détecté. Suppression..."
  kubectl delete ingress risf-ingress -n itsf
  # Attendre que l'Ingress soit complètement supprimé
  while kubectl get ingress risf-ingress -n itsf &>/dev/null; do
    echo "En attente de la suppression de l'Ingress existant..."
    sleep 2
  done
  echo "Ingress supprimé avec succès."
fi

# Vérifier s'il existe un Ingress de Helm qui pourrait causer des conflits (eg: 'risf-risf')
if kubectl get ingress -n risf &>/dev/null; then
  echo "Ingress dans le namespace risf détecté. Cela pourrait causer des conflits..."
  if kubectl get ingress -n risf | grep -q "hello-risf"; then
    echo "⚠️ AVERTISSEMENT: Un Ingress pour 'hello-risf.local.domain' existe dans le namespace risf."
    echo "Cela peut causer un conflit. Considérez de désinstaller le déploiement Helm avant de continuer."
    read -p "Voulez-vous continuer malgré ce conflit potentiel? (o/n): " continue_deploy
    if [[ ! "$continue_deploy" =~ ^[Oo]$ ]]; then
      echo "Déploiement annulé par l'utilisateur. Désinstallez d'abord les releases Helm avec:"
      echo "helm uninstall risf -n risf"
      exit 1
    fi
  fi
fi

# Puis créer le compte de service et les droits RBAC
kubectl apply -f "$SCRIPT_DIR/k8s/service-account.yaml"

# Déployer les ressources
kubectl apply -f "$SCRIPT_DIR/k8s/deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/service.yaml"
kubectl apply -f "$SECRET_FILE"
kubectl apply -f "$SCRIPT_DIR/k8s/ingress.yaml"

# Supprimer le fichier secret temporaire
rm -f "$SECRET_FILE"

echo "5. Vérification du déploiement..."
echo "Attendez que tous les pods soient prêts..."
kubectl wait --for=condition=ready pod -l app=risf-app --timeout=60s -n itsf || true

echo "6. Informations sur l'Ingress déployé:"
kubectl get ingress risf-ingress -n itsf

echo "Configuration terminée! Votre application RISF est accessible via HTTPS:"
echo "- https://$DOMAIN"
echo "- https://www.$DOMAIN"
echo "N'oubliez pas de configurer votre DNS pour pointer vers l'adresse IP de l'Ingress."
