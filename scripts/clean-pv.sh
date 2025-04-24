#!/bin/bash
set -e

# Ce script supprime un volume persistant (PV) dans Kubernetes
# en supprimant d'abord les PVCs associés, puis les finalizers

# Vérifier que kubectl est installé
if ! command -v kubectl &> /dev/null; then
    echo "kubectl n'est pas installé. Veuillez l'installer avant d'exécuter ce script."
    exit 1
fi

# Si un argument est fourni, l'utiliser comme nom du PV
if [ $# -ge 1 ]; then
    PV_NAME=$1
    FORCE=false
    if [ "$2" = "--force" ]; then
        FORCE=true
    fi

    # Vérifier si le PV existe
    if ! kubectl get pv "$PV_NAME" &>/dev/null; then
        echo "Le volume persistant $PV_NAME n'existe pas."
        exit 0
    fi

    echo "Traitement du volume persistant $PV_NAME..."
    kubectl get pv "$PV_NAME"

    # Vérifier si des PVCs sont liés à ce PV
    CLAIM_REF=$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.claimRef.name}' 2>/dev/null || echo "")
    CLAIM_NAMESPACE=$(kubectl get pv "$PV_NAME" -o jsonpath='{.spec.claimRef.namespace}' 2>/dev/null || echo "")

    if [ -n "$CLAIM_REF" ] && [ -n "$CLAIM_NAMESPACE" ]; then
        echo "Le PV $PV_NAME est lié au PVC $CLAIM_REF dans le namespace $CLAIM_NAMESPACE"

        # Vérifier si des pods utilisent ce PVC
        PODS_USING_PVC=$(kubectl get pods -n "$CLAIM_NAMESPACE" -o json | jq -r '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName=="'$CLAIM_REF'") | .metadata.name' 2>/dev/null || echo "")

        if [ -n "$PODS_USING_PVC" ]; then
            echo "Les pods suivants utilisent ce PVC et doivent être supprimés d'abord:"
            echo "$PODS_USING_PVC"

            if [ "$FORCE" = true ]; then
                echo "Option --force activée, suppression des pods..."
                for POD in $PODS_USING_PVC; do
                    echo "Suppression du pod $POD dans le namespace $CLAIM_NAMESPACE..."
                    kubectl delete pod "$POD" -n "$CLAIM_NAMESPACE" --force --grace-period=0 || echo "Impossible de supprimer le pod $POD"
                done
            else
                read -p "Voulez-vous supprimer ces pods pour continuer? (o/n): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Oo]$ ]]; then
                    echo "Suppression de $PV_NAME annulée."
                    exit 0
                fi

                for POD in $PODS_USING_PVC; do
                    echo "Suppression du pod $POD dans le namespace $CLAIM_NAMESPACE..."
                    kubectl delete pod "$POD" -n "$CLAIM_NAMESPACE" || echo "Impossible de supprimer le pod $POD"
                done
            fi
        fi

        # Supprimer les finalizers du PVC pour éviter qu'il ne reste bloqué
        echo "Suppression des finalizers du PVC $CLAIM_REF..."
        kubectl patch pvc "$CLAIM_REF" -n "$CLAIM_NAMESPACE" -p '{"metadata":{"finalizers":null}}' || echo "Impossible de supprimer les finalizers du PVC $CLAIM_REF"

        # Supprimer le PVC
        echo "Suppression du PVC $CLAIM_REF dans le namespace $CLAIM_NAMESPACE..."
        if [ "$FORCE" = true ]; then
            kubectl delete pvc "$CLAIM_REF" -n "$CLAIM_NAMESPACE" --force --grace-period=0 || echo "Impossible de supprimer le PVC $CLAIM_REF"
        else
            kubectl delete pvc "$CLAIM_REF" -n "$CLAIM_NAMESPACE" || echo "Impossible de supprimer le PVC $CLAIM_REF"
        fi
    fi

    # Demander confirmation si --force n'est pas défini
    if [ "$FORCE" != true ]; then
        read -p "Voulez-vous supprimer ce volume persistant ($PV_NAME) ? (o/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Oo]$ ]]; then
            echo "Suppression de $PV_NAME annulée."
            exit 0
        fi
    fi

    echo "Suppression du finalizer pour $PV_NAME..."
    kubectl patch pv "$PV_NAME" -p '{"metadata":{"finalizers":null}}' || {
        echo "Échec de la suppression des finalizers pour $PV_NAME"
        exit 1
    }

    echo "Suppression du volume persistant $PV_NAME..."
    if [ "$FORCE" = true ]; then
        kubectl delete pv "$PV_NAME" --force --grace-period=0 || {
            echo "Échec de la suppression de $PV_NAME"
            exit 1
        }
    else
        kubectl delete pv "$PV_NAME" || {
            echo "Échec de la suppression de $PV_NAME"
            exit 1
        }
    fi

    echo "Volume $PV_NAME supprimé avec succès."
    exit 0
fi

# Si aucun argument n'est fourni, obtenir la liste de tous les PV
echo "Recherche de tous les volumes persistants..."
PV_LIST=$(kubectl get pv -o custom-columns=":metadata.name" --no-headers 2>/dev/null || echo "")

if [ -z "$PV_LIST" ]; then
    echo "Aucun volume persistant trouvé."
    exit 0
fi

echo "Les volumes persistants suivants ont été trouvés:"
kubectl get pv
echo

# Pour chaque PV, demander confirmation, supprimer les PVCs associés, les finalizer puis le PV
for PV in $PV_LIST; do
    echo "Traitement du volume persistant $PV..."
    kubectl get pv $PV

    # Vérifier si des PVCs sont liés à ce PV
    CLAIM_REF=$(kubectl get pv "$PV" -o jsonpath='{.spec.claimRef.name}' 2>/dev/null || echo "")
    CLAIM_NAMESPACE=$(kubectl get pv "$PV" -o jsonpath='{.spec.claimRef.namespace}' 2>/dev/null || echo "")

    if [ -n "$CLAIM_REF" ] && [ -n "$CLAIM_NAMESPACE" ]; then
        echo "Le PV $PV est lié au PVC $CLAIM_REF dans le namespace $CLAIM_NAMESPACE"

        # Vérifier si des pods utilisent ce PVC
        PODS_USING_PVC=$(kubectl get pods -n "$CLAIM_NAMESPACE" -o json | jq -r '.items[] | select(.spec.volumes[]?.persistentVolumeClaim.claimName=="'$CLAIM_REF'") | .metadata.name' 2>/dev/null || echo "")

        if [ -n "$PODS_USING_PVC" ]; then
            echo "Les pods suivants utilisent ce PVC et doivent être supprimés d'abord:"
            echo "$PODS_USING_PVC"

            read -p "Voulez-vous supprimer ces pods pour continuer? (o/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Oo]$ ]]; then
                echo "Suppression de $PV annulée. Passage au suivant..."
                continue
            fi

            for POD in $PODS_USING_PVC; do
                echo "Suppression du pod $POD dans le namespace $CLAIM_NAMESPACE..."
                kubectl delete pod "$POD" -n "$CLAIM_NAMESPACE" || echo "Impossible de supprimer le pod $POD"
            done
        fi

        # Supprimer les finalizers du PVC pour éviter qu'il ne reste bloqué
        echo "Suppression des finalizers du PVC $CLAIM_REF..."
        kubectl patch pvc "$CLAIM_REF" -n "$CLAIM_NAMESPACE" -p '{"metadata":{"finalizers":null}}' || echo "Impossible de supprimer les finalizers du PVC $CLAIM_REF"

        # Supprimer le PVC
        echo "Suppression du PVC $CLAIM_REF dans le namespace $CLAIM_NAMESPACE..."
        kubectl delete pvc "$CLAIM_REF" -n "$CLAIM_NAMESPACE" || echo "Impossible de supprimer le PVC $CLAIM_REF"
    fi

    # Demander confirmation pour ce PV spécifique
    read -p "Voulez-vous supprimer ce volume persistant ($PV) ? (o/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Oo]$ ]]; then
        echo "Suppression de $PV annulée. Passage au suivant..."
        continue
    fi

    echo "Suppression du finalizer pour $PV..."
    kubectl patch pv $PV -p '{"metadata":{"finalizers":null}}' || {
        echo "Échec de la suppression des finalizers pour $PV, passage au suivant..."
        continue
    }

    echo "Suppression du volume persistant $PV..."
    kubectl delete pv $PV --force --grace-period=0 || {
        echo "Échec de la suppression de $PV, passage au suivant..."
        continue
    }

    echo "Volume $PV supprimé avec succès."
done

echo "Opération terminée."
echo "Volumes persistants restants:"
kubectl get pv || echo "Aucun"
