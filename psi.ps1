# Imposta il percorso della cartella condivisa di interesse
$sharedFolderPath = "<percorso cartella condivisa>"

# Crea una variabile per archiviare i risultati
$permissions = New-Object System.Collections.ArrayList

# Crea una variabile per il progressivo
$global:progressivo = 1

# Funzione ricorsiva per ottenere i permessi delle cartelle e sottocartelle
function Get-FolderPermissions($folderPath) {
    # Ottieni elenco delle cartelle nella directory specificata
    $folders = Get-ChildItem -Path $folderPath -Directory

    foreach ($folder in $folders) {
        # Ottieni il nome della cartella corrente
        $folderName = $folder.FullName

        # Visualizza il progressivo e il nome della cartella corrente
        Write-Host "# $progressivo - Checking: $folderName"
		
		    # Incrementa il progressivo
        $global:progressivo++

        # Ottieni l'elenco di controllo accessi (ACL) per la cartella corrente
        $acl = Get-Acl -Path $folder.FullName

        foreach ($ace in $acl.Access) {
            # Creazione di un oggetto personalizzato per rappresentare i permessi della cartella
            $permission = [PSCustomObject]@{
                Folder            = $folder.FullName
                Identity          = $ace.IdentityReference
                AccessControlType = $ace.AccessControlType
                FileSystemRights  = $ace.FileSystemRights
                IsInherited       = $ace.IsInherited
            }
            # Aggiunge l'oggetto all'array complessivo e nasconde l'output
			      $permissions.Add($permission) > $null
        }
        
        # Chiamata ricorsiva per ottenere i permessi delle sottocartelle
        Get-FolderPermissions -folderPath $folder.FullName
    }
}

# Richiama la funzione per ottenere i permessi delle cartelle condivise e sottocartelle
Get-FolderPermissions -folderPath $sharedFolderPath

# Salva i risultati in un file CSV
$csvPath = "C:\PermessiCartelle.csv"
$permissions | ForEach-Object { $_ } | Export-Csv -Path $csvPath -NoTypeInformation

# Visualizza un messaggio di conferma
"Permessi esportati correttamente in: $csvPath"
