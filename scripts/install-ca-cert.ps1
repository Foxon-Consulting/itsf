# Script pour installer le certificat CA dans le magasin de certificats Windows (à exécuter en tant qu'administrateur)

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

# Vérifier si le certificat existe
if (-not (Test-Path -Path $caCertPath)) {
    Write-Host "Erreur: Le certificat CA n'a pas été trouvé à l'emplacement: $caCertPath" -ForegroundColor Red
    Write-Host "Veuillez d'abord générer le certificat CA en exécutant le script create-ca.sh" -ForegroundColor Red
    Write-Host "Appuyez sur une touche pour quitter..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host "Installation du certificat CA dans le magasin de certificats Windows..." -ForegroundColor Cyan

try {
    # Importer le certificat dans le magasin "Autorités de certification racines de confiance"
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($caCertPath)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("Root", "LocalMachine")
    $store.Open("ReadWrite")

    # Vérifier si le certificat est déjà installé
    $existingCert = $store.Certificates | Where-Object { $_.Thumbprint -eq $cert.Thumbprint }

    if ($existingCert) {
        Write-Host "Le certificat CA est déjà installé dans le magasin de certificats." -ForegroundColor Yellow
    } else {
        # Ajouter le certificat au magasin
        $store.Add($cert)
        Write-Host "Le certificat CA a été installé avec succès dans le magasin 'Autorités de certification racines de confiance'!" -ForegroundColor Green
    }

    $store.Close()

    Write-Host "`nCertificat installé avec les détails suivants:" -ForegroundColor Cyan
    Write-Host "Sujet: $($cert.Subject)" -ForegroundColor White
    Write-Host "Émetteur: $($cert.Issuer)" -ForegroundColor White
    Write-Host "Période de validité: $($cert.NotBefore) au $($cert.NotAfter)" -ForegroundColor White
    Write-Host "Empreinte: $($cert.Thumbprint)" -ForegroundColor White
}
catch {
    Write-Host "Une erreur s'est produite lors de l'installation du certificat CA:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`nVous pouvez maintenant accéder aux sites suivants sans avertissements de sécurité:" -ForegroundColor Cyan
Write-Host "- https://hello-itsf.local.domain" -ForegroundColor White
Write-Host "- https://www.hello-itsf.local.domain" -ForegroundColor White
Write-Host "- https://hello-risf.local.domain" -ForegroundColor White
Write-Host "- https://www.hello-risf.local.domain" -ForegroundColor White

# Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
if (-not $args[0] -eq "FromBash") {
    Write-Host "`nAppuyez sur une touche pour quitter..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
