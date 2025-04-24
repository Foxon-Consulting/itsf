# Script pour ajouter des entrées dans le fichier hosts (à exécuter en tant qu'administrateur)

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
$backupFile = "$env:TEMP\hosts.bak.$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# Domaines à ajouter
$domains = @(
    "127.0.0.1    hello-itsf.local.domain",
    "127.0.0.1    www.hello-itsf.local.domain",
    "127.0.0.1    hello-risf.local.domain",
    "127.0.0.1    www.hello-risf.local.domain"
)

Write-Host "Mise à jour du fichier hosts..." -ForegroundColor Cyan

# Lire le contenu actuel du fichier hosts
try {
    $currentContent = Get-Content -Path $hostsFile -ErrorAction Stop

    # Créer une sauvegarde du fichier hosts avant toute modification
    Write-Host "Création d'une sauvegarde du fichier hosts: $backupFile" -ForegroundColor Cyan
    Copy-Item -Path $hostsFile -Destination $backupFile -Force
    Write-Host "Sauvegarde créée avec succès." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la lecture ou de la sauvegarde du fichier hosts:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Vérification de sécurité - s'assurer que le fichier hosts n'est pas vide
if ($null -eq $currentContent -or $currentContent.Count -eq 0) {
    Write-Host "ERREUR: Le fichier hosts semble être vide. Abandon de l'opération pour éviter de le corrompre." -ForegroundColor Red
    Write-Host "Veuillez vérifier le fichier hosts manuellement: $hostsFile" -ForegroundColor Yellow

    # Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
    if (-not $args[0] -eq "FromBash") {
        Write-Host "`nAppuyez sur une touche pour quitter..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    exit 1
}

# Vérification de sécurité - s'assurer que le fichier hosts contient au moins localhost
$containsLocalhost = $false
foreach ($line in $currentContent) {
    if ($line -match "127\.0\.0\.1\s+localhost" -or $line -match "::1\s+localhost") {
        $containsLocalhost = $true
        break
    }
}

if (-not $containsLocalhost) {
    Write-Host "AVERTISSEMENT: Le fichier hosts ne semble pas contenir d'entrée localhost." -ForegroundColor Yellow
    Write-Host "Le fichier hosts pourrait être corrompu ou incomplet." -ForegroundColor Yellow
    Write-Host "Voulez-vous continuer malgré tout? (O/N)" -ForegroundColor Yellow

    if (-not $args[0] -eq "FromBash") {
        $response = Read-Host
        if ($response -ne "O" -and $response -ne "o") {
            Write-Host "Opération annulée par l'utilisateur." -ForegroundColor Red
            exit 1
        }
    } else {
        # En mode automatique depuis bash, on continue quand même mais on affiche un avertissement
        Write-Host "Exécution en mode automatique, continuation malgré l'avertissement..." -ForegroundColor Yellow
    }
}

# Vérifier si les entrées existent déjà
$needsUpdate = $false
$newContent = $currentContent

foreach ($domain in $domains) {
    if ($currentContent -notmatch [regex]::Escape($domain)) {
        $needsUpdate = $true
        Write-Host "Entrée à ajouter: $domain" -ForegroundColor Green
    }
    else {
        Write-Host "L'entrée '$domain' existe déjà dans le fichier hosts." -ForegroundColor Yellow
    }
}

# Ajouter les entrées manquantes
if ($needsUpdate) {
    try {
        # Vérifier si le commentaire existe déjà
        $commentExists = $currentContent -match "# Entrées pour ITSF et RISF"

        if (-not $commentExists) {
            $newContent += "`n# Entrées pour ITSF et RISF"
        }

        foreach ($domain in $domains) {
            if ($currentContent -notmatch [regex]::Escape($domain)) {
                $newContent += "`n$domain"
                Write-Host "Ajout de l'entrée: $domain" -ForegroundColor Green
            }
        }

        # Écrire tout le contenu en une seule opération
        Set-Content -Path $hostsFile -Value $newContent -Force -ErrorAction Stop
        Write-Host "Le fichier hosts a été mis à jour avec succès!" -ForegroundColor Green
    }
    catch {
        Write-Host "Une erreur s'est produite lors de la mise à jour du fichier hosts:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "`nEssayez de fermer tous les programmes qui pourraient utiliser le fichier hosts, comme un éditeur de texte ou Notepad." -ForegroundColor Yellow

        # Restauration du fichier hosts
        Write-Host "Restauration de la sauvegarde du fichier hosts..." -ForegroundColor Yellow
        Copy-Item -Path $backupFile -Destination $hostsFile -Force
        Write-Host "Restauration terminée." -ForegroundColor Green
        exit 1
    }
}
else {
    Write-Host "Aucune nouvelle entrée à ajouter. Le fichier hosts est déjà à jour." -ForegroundColor Green
}

# Vider le cache DNS pour appliquer les changements immédiatement
Write-Host "Nettoyage du cache DNS..." -ForegroundColor Cyan
ipconfig /flushdns | Out-Null
Write-Host "Cache DNS vidé avec succès!" -ForegroundColor Green

Write-Host "`nConfiguration DNS terminée. Vous pouvez maintenant accéder aux sites suivants:" -ForegroundColor Cyan
Write-Host "- https://hello-itsf.local.domain" -ForegroundColor White
Write-Host "- https://www.hello-itsf.local.domain" -ForegroundColor White
Write-Host "- https://hello-risf.local.domain" -ForegroundColor White
Write-Host "- https://www.hello-risf.local.domain" -ForegroundColor White
Write-Host "`nN'oubliez pas d'installer le certificat CA dans votre navigateur!" -ForegroundColor Yellow

# Ne pas attendre d'appui sur une touche lors de l'exécution depuis bash
if (-not $args[0] -eq "FromBash") {
    Write-Host "`nAppuyez sur une touche pour quitter..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
