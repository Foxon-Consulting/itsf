#!/bin/bash
set -e

echo "Installation du contrôleur Ingress NGINX sur Kubernetes local..."

# Type de service et ports fixés pour la simplicité
SERVICE_TYPE="LoadBalancer"
HTTPS_PORT=443
HTTP_PORT=80

echo "Mode de service: $SERVICE_TYPE (Docker Desktop/Minikube)"
echo "Configuration avec les ports standards :"
echo "- HTTPS: $HTTPS_PORT"
echo "- HTTP: $HTTP_PORT"

# Créer le namespace pour le contrôleur Ingress
kubectl create namespace ingress-nginx 2>/dev/null || true

# Installer le contrôleur Ingress NGINX
if command -v helm &> /dev/null; then
    echo "Installation via Helm..."
    # Ajouter le dépôt Helm pour NGINX Ingress Controller
    helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
    helm repo update

    # Configurer les arguments Helm pour LoadBalancer avec ports standards
    HELM_ARGS="--namespace ingress-nginx --set controller.publishService.enabled=true --set controller.service.type=$SERVICE_TYPE"
    HELM_ARGS="$HELM_ARGS --set controller.service.ports.https=$HTTPS_PORT"
    HELM_ARGS="$HELM_ARGS --set controller.service.ports.http=$HTTP_PORT"

    # Exécuter la commande helm
    eval "helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx $HELM_ARGS"
else
    echo "Installation via kubectl apply..."
    # Installer directement avec kubectl
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml
fi

echo "Attente du démarrage du contrôleur Ingress NGINX..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s || true

echo "Vérification de l'installation..."
kubectl get pods -n ingress-nginx
kubectl get services -n ingress-nginx

echo "Le contrôleur Ingress NGINX a été installé avec succès!"
echo ""
