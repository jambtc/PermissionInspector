# PermissionInspector

PermissionInspector (PSI) è uno script PowerShell che consente di ottenere i permessi di accesso delle cartelle all'interno di una cartella condivisa, nonché di rimuoverli in base alle specifiche dell'utente.

Lo script richiede all'utente di specificare il percorso della cartella condivisa e il codice fiscale dell'utente desiderato. Se non si inserisce il codice fiscale, è possibile solo effettuare l'operazione di estrazione dei permessi.
In base all'azione scelta dall'utente (estrazione o eliminazione dei permessi), lo script esegue le operazioni corrispondenti, inclusa la scansione delle cartelle ottenendo gli elenchi di controllo accessi (ACL) e la gestione dei permessi. I risultati vengono salvati in un file CSV.

L'output fornisce informazioni dettagliate sugli utenti, i tipi di accesso, i diritti di file e se i permessi sono ereditati o no.

PermissionInspector consente agli amministratori di sistemi di ottenere una panoramica completa dei permessi sulle cartelle condivise, semplificando così la gestione e l'audit dei controlli di accesso nelle infrastrutture basate su Windows.

## Flusso

Il flusso del programma è il seguente:

1. Viene richiesto all'utente di inserire il percorso della cartella condivisa.
1. Viene richiesto all'utente di inserire il codice fiscale dell'utente (lasciando vuoto per ottenere tutti i permessi).
1. Se viene inserito un codice fiscale, viene richiesto all'utente di inserire il nome del dominio.
1. Viene richiesto il disco su cui salvare il file CSV
1. Se viene inserito un codice fiscale, viene richiesta all'utente l'azione desiderata: "E" per estrarre i permessi o "D" per eliminarli.
1. Se non è stato inserito un codice fiscale o se è stato inserito, ma si è scelto l'azione di estrazione, viene prodotto un file CSV.
