# Script pour supprimer les entrées DNS du fichier hosts (à exécuter en tant qu'administrateur)

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

# Chemin du fichier hosts
$hostsFile = "$env:windir\System32\drivers\etc\hosts"

# Domaines à supprimer
$domains = @(
    "127.0.0.1    hello-itsf.local.domain",
    "127.0.0.1    www.hello-itsf.local.domain",
    "127.0.0.1    hello-risf.local.domain",
    "127.0.0.1    www.hello-risf.local.domain"
)

Write-Host "Nettoyage du fichier hosts..." -ForegroundColor Cyan

# Lire le contenu actuel du fichier hosts
try {
    $content = Get-Content -Path $hostsFile -ErrorAction Stop
}
catch {
    Write-Host "Erreur lors de la lecture du fichier hosts:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    # Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
    if (-not $args[0] -eq "FromBash") {
        Write-Host "`nAppuyez sur une touche pour quitter..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit 1
}

# Filtrer les lignes à conserver (supprimer les entrées des domaines et le commentaire)
$newContent = @()
$skipNext = $false

foreach ($line in $content) {
    $skipLine = $false

    # Vérifier s'il s'agit d'une ligne de commentaire pour nos entrées
    if ($line -match "# Entrées pour ITSF et RISF") {
        $skipLine = $true
    }

    # Vérifier s'il s'agit d'une des entrées à supprimer
    foreach ($domain in $domains) {
        if ($line -match [regex]::Escape($domain)) {
            $skipLine = $true
            break
        }
    }

    # Ajouter la ligne au nouveau contenu si elle ne doit pas être supprimée
    if (-not $skipLine) {
        $newContent += $line
    }
}

# Vérifier si des modifications sont nécessaires
$domainsFound = $false
foreach ($domain in $domains) {
    if ($content -match [regex]::Escape($domain)) {
        $domainsFound = $true
        break
    }
}

if (-not $domainsFound) {
    Write-Host "Aucune entrée à supprimer. Le fichier hosts est déjà nettoyé." -ForegroundColor Green

    # Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
    if (-not $args[0] -eq "FromBash") {
        Write-Host "`nAppuyez sur une touche pour quitter..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit 0
}

# S'assurer que le nouveau contenu n'est pas vide
if ($newContent.Count -eq 0) {
    Write-Host "ERREUR: Le nouveau contenu du fichier hosts serait vide." -ForegroundColor Red
    Write-Host "Opération annulée pour éviter de vider le fichier hosts." -ForegroundColor Red

    # Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
    if (-not $args[0] -eq "FromBash") {
        Write-Host "`nAppuyez sur une touche pour quitter..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit 1
}

# Écrire le contenu modifié
try {
    Set-Content -Path $hostsFile -Value $newContent -Force -ErrorAction Stop
    Write-Host "Entrées DNS supprimées du fichier hosts." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la modification du fichier hosts:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host "`nEssayez de fermer tous les programmes qui pourraient utiliser le fichier hosts." -ForegroundColor Yellow

    # Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
    if (-not $args[0] -eq "FromBash") {
        Write-Host "`nAppuyez sur une touche pour quitter..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit 1
}

# Vider le cache DNS pour appliquer les changements immédiatement
Write-Host "Nettoyage du cache DNS..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null
Write-Host "Cache DNS vidé avec succès!" -ForegroundColor Green

# Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
if (-not $args[0] -eq "FromBash") {
    Write-Host "`nAppuyez sur une touche pour quitter..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
