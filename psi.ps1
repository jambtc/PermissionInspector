# Crea una variabile in formato array per archiviare i risultati
$permissions = New-Object System.Collections.ArrayList

# Crea una variabile globale per il progressivo
$global:progressivo = 0

# Crea una variabile globale per il totale delle cartelle
$global:totalFolders = 0

# Funzione che mostra il progressivo della scansione e il nome cartella
function Show-Progress {
    param(
        [int]$PercentComplete,
        [string]$FolderName
    )
    
    $status = "Progresso: {0}%" -f $PercentComplete
    $progressBarLength = [math]::Floor($PercentComplete / 2)

    $progressBar = "▓" * $progressBarLength
    $emptySpace = "░" * (50 - $progressBarLength)
    $progressBarText = "{0}{1}" -f $progressBar, $emptySpace

    # Ottieni la larghezza dello schermo
    $screenWidth = $host.UI.RawUI.WindowSize.Width

    # Testo da visualizzare
    $text = "`rScansione in corso: [$progressBarText] $status - $FolderName                                     "

    # Limita la lunghezza del testo alla larghezza dello schermo
    $limitedText = $text.Substring(0, [Math]::Min($text.Length, $screenWidth))

    # Visualizza il testo limitato
    Write-Host $limitedText -NoNewline
}


# Funzione che calcola il totale delle subfolders
function Get-TotalFolders($folderPath) {
    # Aggiungi le sottocartelle alla lista
    $folders = Get-ChildItem -Path $folderPath -Directory

    foreach ($folder in $folders) {
        $global:totalFolders ++
        # Write-Progress -Activity "Conteggio cartelle in corso..." -Status "Progressivo: $global:totalFolders" -PercentComplete $x
        Write-Host "`rLettura cartelle in corso: # $global:totalFolders    " -NoNewline

        # Chiamata ricorsiva per ottenere i permessi delle sottocartelle
        Get-TotalFolders -folderPath $folder.FullName
    }
}

# Funzione ricorsiva per ottenere i permessi delle cartelle e sottocartelle
function Get-FolderPermissions($folderPath, $removeUser) {
    # Elimina i permessi dalla cartella principale
    if (-not [string]::IsNullOrEmpty($codiceFiscale) -and $null -ne $removeUser) {
        # Ottieni l'elenco di controllo accessi (ACL) per la cartella principale
        $acl = Get-Acl -Path $folderPath

        $accesToRemove = $acl.Access | ? { $_.IsInherited -eq $false -and $_.IdentityReference -eq $removeUser }
        if ($null -ne $accessToRemove){
            $acl.RemoveAccessRuleAll($accesToRemove)
            Write-Host "--> Rimozione permessi."
            
            # Applica le modifiche all'ACL della cartella
            Set-Acl -AclObject $acl $folderPath
        }
    } else {
        # Aggiungi le sottocartelle alla lista
        $folders = Get-ChildItem -Path $folderPath -Directory
        
        foreach ($folder in $folders) {
            # Ottieni il nome della cartella corrente
            $folderName = $folder.FullName
            
            # Incrementa il progressivo
            $global:progressivo++
            
            # Visualizza il progressivo e il nome della cartella corrente
            Show-Progress -PercentComplete (($global:progressivo / $global:totalFolders) * 100) -FolderName $folderName
    
            # Ottieni l'elenco di controllo accessi (ACL) per la cartella corrente
            $acl = Get-Acl -Path $folder.FullName
    
            foreach ($access in $acl.Access) {
                # Imposta un trigger a false
                $trigger = 0

                if ([string]::IsNullOrEmpty($codiceFiscale)) {
                    $trigger = 1
                } elseif ($access.IdentityReference.Value.ToUpper() -eq $codiceFiscale){
                    $trigger = 1
                }

                if ($trigger){
                    # Creazione di un oggetto personalizzato per rappresentare i permessi della cartella
                    $permission = [PSCustomObject]@{
                        Folder            = $folder.FullName
                        Identity          = $access.IdentityReference
                        AccessControlType = $access.AccessControlType
                        FileSystemRights  = $access.FileSystemRights
                        IsInherited       = $access.IsInherited
                    }
                    # Aggiunge l'oggetto all'array complessivo
                    $permissions.Add($permission) > $null
                }
            }
    
            # Chiamata ricorsiva per ottenere i permessi delle sottocartelle
            Get-FolderPermissions -folderPath $folder.FullName
        }
    }

}

# Richiedi il percorso della cartella tramite prompt
$sharedFolderPath = Read-Host -Prompt "Inserisci il percorso della cartella condivisa"

# Verifica che il percorso della cartella esista e sia raggiungibile
if (-not (Test-Path $sharedFolderPath -PathType Container)) {
    Write-Host "La cartella specificata non esiste o non è accessibile."
    exit
}

# Richiedi il codice fiscale dell'utente tramite prompt
$codiceFiscale = Read-Host -Prompt "Inserisci il codice fiscale dell'utente (Lascia vuoto per tutti)"

# Trasformo il codice fiscale in maiuscolo ed aggiungo il Dominio
if (-not [string]::IsNullOrEmpty($codiceFiscale)) {
    $codiceFiscale = $codiceFiscale.ToUpper()

    # Richiedi il dominio dell'utente tramite prompt
    $dominio = Read-Host -Prompt "Inserisci il nome del dominio"

    # Aggiungo il dominio al codice fiscale 
    if (-not [string]::IsNullOrEmpty($dominio)) {
        $codiceFiscale = $dominio.ToUpper() + "\" + $codiceFiscale
    } else {
        Write-Host "Il nome del dominio è necessario se hai inserito il codice fiscale."
        exit
    }
}

if ([string]::IsNullOrEmpty($codiceFiscale)) {
    # Se non ho inserito il codice fiscale posso solo estrarre
    $action = "E"
} else {
    # Richiesta dell'azione desiderata all'utente
    $action = Read-Host -Prompt "Inserisci 'E' per estrarre i permessi o 'D' per eliminarli"
}

# Verifica dell'azione desiderata
if ($action -eq "E") { # Azione: Estrarre i permessi
    # Richiama la funzione per contare il totale delle cartelle
    Get-TotalFolders -folderPath $sharedFolderPath

    # Visualizza completamento dell'attività
    Write-Host "`rLettura cartelle completato: # $global:totalFolders     " 

    # Richiama la funzione per ottenere i permessi delle cartelle condivise e sottocartelle
    Get-FolderPermissions -folderPath $sharedFolderPath

    # Salva i risultati in un file CSV
    $csvPath = "C:\PermessiCartelle.csv"
    $permissions | ForEach-Object { $_ } | Export-Csv -Path $csvPath -NoTypeInformation

    # Visualizza un messaggio di conferma
    Write-Host "`r"
    Write-Host "Permessi esportati correttamente in: $csvPath"
    exit
}
elseif ($action -eq "D") { # Azione: Eliminare i permessi
    # Richiama la funzione per contare il totale delle cartelle
    Get-TotalFolders -folderPath $sharedFolderPath

    # Visualizza completamento dell'attività
    Write-Host "`rLettura cartelle completato: # $global:totalFolders     " 

    # Richiama la funzione per ottenere i permessi delle cartelle condivise e sottocartelle
    Get-FolderPermissions -folderPath $sharedFolderPath -removeUser $codiceFiscale

    # Salva i risultati in un file CSV
    $csvPath = "C:\PermessiCartelle.csv"
    $permissions | ForEach-Object { $_ } | Export-Csv -Path $csvPath -NoTypeInformation

    # Visualizza un messaggio di conferma
    Write-Host "`r"
    Write-Host "Permessi eliminati correttamente."
    exit
}
else {
    # Azione non valida
    Write-Host "Azione non valida. Riprova."
    exit
}





