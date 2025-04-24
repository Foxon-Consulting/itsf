# Script pour supprimer le certificat CA du magasin de certificats Windows (à exécuter en tant qu'administrateur)

# Vérifier si le script est exécuté en tant qu'administrateur
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." -ForegroundColor Red
    Write-Host "Veuillez fermer cette fenêtre et exécuter PowerShell en tant qu'administrateur, puis relancer ce script." -ForegroundColor Red
    Write-Host "Appuyez sur une touche pour quitter..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Chemin du certificat CA
$caCertPath = Join-Path -Path $PSScriptRoot -ChildPath "..\certs\ca.crt"

# Si le certificat n'existe pas, rien à faire
if (-not (Test-Path -Path $caCertPath)) {
    Write-Host "Certificat CA non trouvé. Aucune action nécessaire." -ForegroundColor Yellow

    # Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
    if (-not $args[0] -eq "FromBash") {
        Write-Host "`nAppuyez sur une touche pour quitter..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit 0
}

Write-Host "Suppression du certificat CA du magasin de certificats Windows..." -ForegroundColor Cyan

try {
    # Charger le certificat pour obtenir son empreinte
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($caCertPath)
    $thumbprint = $cert.Thumbprint

    # Ouvrir le magasin de certificats
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
    $store.Open("ReadWrite")

    # Chercher le certificat par empreinte
    $certToRemove = $store.Certificates | Where-Object { $_.Thumbprint -eq $thumbprint }

    if ($certToRemove) {
        # Supprimer le certificat
        $store.Remove($certToRemove)
        Write-Host "Certificat CA supprimé du magasin de certificats." -ForegroundColor Green
    } else {
        Write-Host "Certificat CA non trouvé dans le magasin. Aucune action nécessaire." -ForegroundColor Yellow
    }

    $store.Close()
}
catch {
    Write-Host "Erreur lors de la suppression du certificat CA:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
if (-not $args[0] -eq "FromBash") {
    Write-Host "`nAppuyez sur une touche pour quitter..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
