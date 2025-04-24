#!/bin/bash
set -e

# Ce script supprime tous les volumes persistants (PV) dans Kubernetes
# en utilisant le script clean-pv.sh pour chaque PV, en désactivant les PVCs associés d'abord

# Vérifier que kubectl est installé
if ! command -v kubectl &> /dev/null; then
    echo "kubectl n'est pas installé. Veuillez l'installer avant d'exécuter ce script."
    exit 1
fi

# Vérifier que le script clean-pv.sh existe
if [ ! -f "./scripts/clean-pv.sh" ]; then
    echo "Erreur: Le script ./scripts/clean-pv.sh n'existe pas."
    exit 1
fi

# Vérifier si jq est installé (nécessaire pour le parsing JSON dans clean-pv.sh)
if ! command -v jq &> /dev/null; then
    echo "ATTENTION: jq n'est pas installé. Cet outil est recommandé pour une meilleure détection des pods liés aux PVCs."
    echo "L'utilisation de certaines fonctionnalités peut être limitée sans jq."
    echo
fi

# Demander confirmation générale
echo "ATTENTION: Cette opération va supprimer tous les volumes persistants (PV) du cluster"
echo "ainsi que les PVCs et potentiellement les pods associés."
echo "Cette action est IRRÉVERSIBLE et peut entraîner une PERTE DE DONNÉES."
read -p "Êtes-vous sûr de vouloir continuer? (o/n): " -n 1 -r CONFIRM
echo
if [[ ! $CONFIRM =~ ^[Oo]$ ]]; then
    echo "Opération annulée."
    exit 0
fi

# Obtenir la liste de tous les PV
echo "Recherche de tous les volumes persistants..."
PV_LIST=$(kubectl get pv -o custom-columns=":metadata.name" --no-headers 2>/dev/null || echo "")

if [ -z "$PV_LIST" ]; then
    echo "Aucun volume persistant trouvé."
    exit 0
fi

echo "Les volumes persistants suivants ont été trouvés:"
kubectl get pv
echo

# Pour chaque PV, utiliser le script clean-pv.sh avec l'option --force
for PV in $PV_LIST; do
    echo "Traitement du volume persistant $PV..."
    ./scripts/clean-pv.sh "$PV" --force
    # Le script clean-pv.sh va maintenant gérer la suppression des PVCs et pods associés automatiquement
done

echo "Opération terminée."
echo "Volumes persistants restants:"
kubectl get pv || echo "Aucun"
