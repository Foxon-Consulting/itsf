#!/bin/bash

# Obtenir le chemin absolu du répertoire courant
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Définir les chemins absolus des fichiers de ressources
PV_FILE="$ROOT_DIR/itsf/k8s/pv.yaml"
PVC_FILE="$ROOT_DIR/itsf/k8s/pvc.yaml"
NAMESPACE="itsf"

# Vérifier que les fichiers existent
if [ ! -f "$PV_FILE" ]; then
  echo "Erreur: Le fichier $PV_FILE n'existe pas."
  exit 1
fi

if [ ! -f "$PVC_FILE" ]; then
  echo "Erreur: Le fichier $PVC_FILE n'existe pas."
  exit 1
fi

# Vérifier si le namespace existe, sinon le créer
echo "Vérification du namespace $NAMESPACE..."
kubectl get namespace $NAMESPACE &> /dev/null
if [ $? -ne 0 ]; then
  echo "Création du namespace $NAMESPACE..."
  kubectl create namespace $NAMESPACE
fi

# Appliquer le PersistentVolume (les PV sont des ressources au niveau cluster, pas de namespace)
echo "Application du PersistentVolume..."
kubectl apply -f "$PV_FILE"

# Vérifier le statut
if [ $? -eq 0 ]; then
  echo "✅ PersistentVolume créé avec succès."
else
  echo "❌ Erreur lors de la création du PersistentVolume."
  exit 1
fi
