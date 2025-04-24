#!/bin/bash
set -e

echo "====================================================================="
echo "  Vérification post-installation de l'environnement ITSF/RISF"
echo "====================================================================="
echo ""

# Obtenir le chemin du répertoire du script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "1. Vérification de la configuration..."
echo "----------------------------------------------------------------------"
echo "Ingress déployés :"
kubectl get ingress --all-namespaces | grep -E 'itsf|risf'
echo ""
echo "Pods en cours d'exécution :"
kubectl get pods -n itsf
if kubectl get namespace risf &>/dev/null; then
  kubectl get pods -n risf
fi
echo ""
echo "Services :"
kubectl get services -n itsf
if kubectl get namespace risf &>/dev/null; then
  kubectl get services -n risf
fi
echo ""

# Attendre que tous les pods soient prêts
echo "Attente que tous les pods soient prêts..."
kubectl wait --for=condition=ready pod -l app=itsf-app --timeout=60s -n itsf || true
if kubectl get namespace risf &>/dev/null; then
  kubectl wait --for=condition=ready pod -l app=risf-app --timeout=60s -n risf || true
fi

echo "====================================================================="
echo "  Installation terminée!"
echo "====================================================================="
echo ""
echo "Pour accéder à vos sites:"
echo ""

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    echo "Sur Windows, la configuration DNS et les certificats peuvent être installés avec:"
    echo "powershell.exe -ExecutionPolicy Bypass -File \"$ROOT_DIR/scripts/install-hosts.ps1\" FromBash"
    echo "powershell.exe -ExecutionPolicy Bypass -File \"$ROOT_DIR/scripts/install-ca-cert.ps1\" FromBash"
else
    echo "1. Assurez-vous que les entrées DNS sont configurées dans votre fichier hosts"
    echo "   Sur Linux/macOS: ajoutez les entrées suivantes à /etc/hosts:"
    echo "   127.0.0.1 hello-itsf.local.domain www.hello-itsf.local.domain"
    echo "   127.0.0.1 hello-risf.local.domain www.hello-risf.local.domain"
    echo ""
    echo "2. Installez le certificat CA dans votre navigateur"
    echo "   Le certificat se trouve dans le dossier certs/ca.crt"
    echo ""
fi

echo "3. Accédez à vos sites via:"
echo "   - https://hello-itsf.local.domain"
echo "   - https://hello-risf.local.domain"

echo ""
echo "Si vous rencontrez des problèmes, consultez le README.md pour le dépannage."
echo "====================================================================="

# Afficher un résumé des points d'accès
echo ""
echo "RÉSUMÉ DE LA CONFIGURATION:"
echo "-------------------------------------------------------------------"
echo "Sites Web accessibles sur votre environnement local:"
echo "- ITSF: https://hello-itsf.local.domain"
echo "- RISF: https://hello-risf.local.domain"
echo ""
echo "Pour la documentation complète, voir README.md"
echo "====================================================================="
