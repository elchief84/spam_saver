# Call Guard — Use Cases

**Document ID:** CG-UC-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parent:** CG-OVW-001

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Aldo (PM) | 2026-10-10 | Aldo |
| Reviewer | — | — | — |
| Approver (QA/RA) | — | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft |

---

## Document Scope

Questo documento definisce tutti gli Use Case (UC) di Call Guard, app Android per la gestione delle chiamate da numeri sconosciuti.

Gli UC descrivono *cosa* ciascun attore deve ottenere e *perché* — non come il sistema li implementa internamente. Coprono: attivazione della protezione, intercettazione e rifiuto automatico prima dello squillo, registrazione del tentativo, invio dell'SMS automatico, intercettazione delle risposte SMS all'apertura dell'app con classificazione rapida, gestione di whitelist/blacklist e configurazione del testo SMS.

Documento padre: Overview di progetto (obiettivo, ambito, RF-1–RF-10). Prossimo documento nel pacchetto: User Needs.

Fuori perimetro (non coperto dagli UC): iOS, cloud/backend e sincronizzazione multi-dispositivo, chiamate in uscita.

---

## Actor Definitions

| Actor | Description |
|---|---|
| **Utente** | Proprietario del dispositivo. Configura l'app, consulta la cronologia, classifica i numeri, gestisce whitelist/blacklist e testo SMS. |
| **Chiamante sconosciuto** | Persona che chiama da un numero visibile non presente in rubrica/whitelist. Subisce il rifiuto e riceve l'SMS automatico; può rispondere via SMS per identificarsi. |
| **Android OS** | Sistema operativo Android 10+ nel ruolo di call screening (CallScreeningService, ruolo ROLE_CALL_SCREENING) e provider di telefonia/SMS. Attore secondario/di piattaforma che notifica le chiamate e recapita gli SMS. |

---

## UC-01 — Attivare la protezione anti-sconosciuti

**Actor:** Utente (primario); Android OS (secondario)
**Preconditions:**
- L'app è installata su dispositivo Android 10+.
- L'utente non ha ancora assegnato all'app il ruolo di call screening oppure non ha ancora concesso i permessi richiesti (telefono, rubrica, SMS).

**Story:**

As an **Utente**, I want to attivare la protezione con una procedura guidata so that le chiamate sconosciute vengano intercettate e rifiutate senza che io debba pensarci.

**Main Flow:**

1. L'utente apre l'app e avvia la procedura di attivazione.
2. L'app mostra lo stato di ciascun prerequisito: ruolo di call screening, accesso a telefono/chiamate, accesso alla rubrica, invio/lettura SMS.
3. L'utente assegna il ruolo di call screening e concede i permessi richiesti tramite i dialoghi di sistema.
4. L'app verifica ogni autorizzazione e mostra la conferma "Protezione attiva".

**Unhappy Paths:**

- L'utente nega un permesso o non assegna il ruolo → l'app resta in stato "Protezione non attiva", indica esattamente cosa manca e come rimediare; nessun rifiuto automatico viene eseguito.
- Il ruolo di call screening è già assegnato a un'altra app → l'app lo segnala e rimanda alle impostazioni di sistema; nessuna intercettazione finché il ruolo non è assegnato a Call Guard.
- Il dispositivo non supporta il ruolo di call screening (versione Android < 10) → l'app informa che il dispositivo non è compatibile e non attiva la protezione.

**Postconditions:**

- Lo stato di attivazione (ruolo + permessi) è registrato e visibile in-app.
- Se tutti i prerequisiti sono soddisfatti, UC-02/UC-03/UC-04 sono operativi.

---

## UC-02 — Rifiutare automaticamente una chiamata sconosciuta

**Actor:** Chiamante sconosciuto (trigger); Android OS (notifica la chiamata); Utente (beneficiario)
**Preconditions:**
- La protezione è attiva (UC-01 completato: ruolo assegnato, permessi concessi).
- Esiste una whitelist, una blacklist e l'accesso in lettura alla rubrica del dispositivo.

**Story:**

As an **Utente**, I want to non essere disturbato dai numeri che non conosco so that il telefono non squilla e io ritrovo poi tutto nella cronologia. As a **Chiamante sconosciuto**, I want to ricevere subito un segnale chiaro (rifiuto + SMS) so that so come farmi identificare.

**Main Flow:**

1. Android OS notifica all'app una chiamata in ingresso prima dello squillo, con il numero chiamante quando disponibile.
2. L'app confronta il numero con rubrica, whitelist e blacklist.
3. Se il numero è visibile e non è né in rubrica né in whitelist, l'app ordina il rifiuto (disconnessione/silenziamento) entro il timeout di piattaforma.
4. Se il numero è in rubrica o in whitelist, l'app lascia passare la chiamata normalmente; se è in blacklist, l'app la rifiuta sempre (vedi configurazione in UC-07 per l'SMS).

**Unhappy Paths:**

- Il numero è nascosto/sconosciuto (non fornito dal carrier) → l'app non può ricontattarlo: applica la politica configurata per i numeri anonimi (di default: lascia passare) e non tenta alcun invio SMS.
- I permessi o il ruolo sono stati revocati dopo l'attivazione → l'app non può schermare: la chiamata passa normalmente e, alla successiva apertura, l'app segnala "Protezione non attiva".
- La risposta supera il timeout di piattaforma → il sistema fa squillare comunque; nessun rifiuto parziale, la chiamata non viene registrata come "rifiutata da Call Guard".

**Postconditions:**

- La chiamata sconosciuta è stata rifiutata senza squillo (caso felice) oppure è passata secondo le regole whitelist/rubrica/blacklist/anonimo.
- Si innescano UC-03 (registrazione) e, se applicabile, UC-04 (SMS automatico).

---

## UC-03 — Registrare il tentativo rifiutato in cronologia

**Actor:** Utente (beneficiario); Android OS (fornisce data/ora/numero)
**Preconditions:**
- Una chiamata è stata trattata da UC-02 con esito "rifiutata da Call Guard".

**Story:**

As an **Utente**, I want to vedere ogni chiamata rifiutata con numero, data/ora ed esito so that ho una traccia consultabile e posso decidere cosa farne.

**Main Flow:**

1. Dopo il rifiuto, l'app crea una voce di cronologia con: numero chiamante, data/ora, esito (rifiutata), origine della decisione (non in rubrica/whitelist oppure blacklist), stato invio SMS, note (vuote di default).
2. L'app salva la voce nello storage locale persistente.
3. L'utente apre la lista "Chiamate bloccate" e ritrova la voce in ordine cronologico inverso.

**Unhappy Paths:**

- Lo storage locale non è scrivibile (spazio esaurito/corruzione) → la voce non viene persa in silenzio: l'app segnala l'errore all'apertura successiva e riprova il salvataggio.
- Record duplicato per richiamate ravvicinate → l'app non sovrascrive: crea una voce distinta per ogni tentativo con data/ora propria.

**Postconditions:**

- Ogni chiamata rifiutata è presente nella cronologia locale con numero, data/ora, esito, stato SMS e note.
- La cronologia sopravvive al riavvio del dispositivo; nessun dato lascia il dispositivo e nessun numero compare nei log.

---

## UC-04 — Inviare l'SMS automatico al numero rifiutato

**Actor:** Chiamante sconosciuto (destinatario); Utente (configura il testo, vedi UC-08)
**Preconditions:**
- Una chiamata è stata rifiutata da UC-02 e registrata da UC-03.
- Il numero è visibile e ricontattabile via SMS.
- Il numero non è in blacklist con invio SMS disabilitato (vedi UC-07).

**Story:**

As an **Utente**, I want to che ogni sconosciuto rifiutato riceva subito il mio messaggio standard so that chi ha un motivo valido può identificarsi via SMS senza che io lo chiami. As a **Chiamante sconosciuto**, I want to capire perché la chiamata è stata rifiutata so that so cosa fare (inviare un SMS di presentazione).

**Main Flow:**

1. L'app compone l'SMS con il testo configurato dall'utente (default: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione.").
2. L'app invia l'SMS al numero rifiutato tramite il provider SMS di sistema.
3. L'app aggiorna la voce di cronologia (UC-03) con lo stato "SMS inviato / fallito" e l'ora di invio.

**Unhappy Paths:**

- Invio SMS fallito (assenza rete, credito esaurito, blocco carrier) → la voce di cronologia riporta "SMS non inviato" con motivo generico (senza PII nei log); l'app propone all'apertura successiva di ritentare manualmente.
- Numero non valido per SMS (fisso non abilitato, short code, numero anonimo) → nessun tentativo di invio; stato registrato come "SMS non applicabile".
- Il numero è in blacklist con invio SMS disabilitato → nessun invio; la cronologia indica "rifiutata da blacklist, SMS disabilitato".

**Postconditions:**

- Il chiamante sconosciuto ha ricevuto l'SMS di identificazione (caso felice).
- La voce di cronologia riporta lo stato reale dell'invio.

---

## UC-05 — Consultare la cronologia delle chiamate bloccate

**Actor:** Utente
**Preconditions:**
- Esiste almeno una voce di cronologia (oppure la lista è vuota e l'app deve mostrarlo chiaramente).

**Story:**

As an **Utente**, I want to scorrere la lista dei tentativi con tutte le info acquisite so that capisco chi ha chiamato, quando, e se l'SMS è partito.

**Main Flow:**

1. L'utente apre la vista "Chiamate bloccate".
2. L'app mostra la lista in ordine cronologico inverso con numero, data/ora, esito, stato SMS e anteprima note.
3. L'utente tocca una voce e ne apre il dettaglio, da cui può aggiungere note o avviare la classificazione (UC-06/UC-07).

**Unhappy Paths:**

- Cronologia vuota → l'app mostra uno stato vuoto esplicito ("Nessuna chiamata bloccata") invece di una lista bianca ambigua.
- Dati locali danneggiati → l'app mostra un errore leggibile e non va in crash; le voci integre restano consultabili.

**Postconditions:**

- L'utente ha visionato i tentativi; eventuali note aggiunte sono salvate in locale.
- Nessuna modifica al comportamento di screening (sola lettura, salvo avvio esplicito di UC-06/UC-07).

---

## UC-06 — Classificare un numero dalla risposta SMS (Accetta / Rifiuta)

**Actor:** Utente
**Preconditions:**
- L'app viene aperta dall'utente.
- Esiste almeno un numero in attesa di classificazione: chiamata rifiutata (UC-03) a cui è seguita o meno una risposta SMS, oppure SMS in ingresso intercettato.

**Story:**

As an **Utente**, I want to leggere all'apertura dell'app le risposte SMS dei numeri bloccati e decidere con un tocco so that "promuovo" chi si è presentato (whitelist) o "bandisco" lo spam (blacklist).

**Main Flow:**

1. All'apertura dell'app, l'app intercetta e mostra nella vista dedicata gli SMS in ingresso collegati ai numeri rifiutati, con numero, testo e data/ora.
2. Per ciascun numero l'app offre due CTA: "Accetta (whitelist)" e "Rifiuta (blacklist)".
3. L'utente tocca una delle due CTA (ed eventualmente compila nome/note/categoria proposti nel profilo).
4. L'app sposta il numero nella lista scelta e conferma l'azione; da quel momento il comportamento di UC-02 cambia immediatamente per quel numero (RF-10).

**Unhappy Paths:**

- SMS da un numero mai rifiutato o non collegabile → mostrato comunque come "non collegato" senza CTA automatiche distruttive; la classificazione resta manuale via UC-07.
- L'utente tocca la CTA sbagliata → può annullare/ripristinare subito dalla conferma o spostare il numero dall'altra lista (UC-07); nessuna perdita di cronologia.
- Permesso di lettura SMS revocato → la vista mostra "accesso SMS mancante" con rimando alle impostazioni; nessuna classificazione su dati non letti.

**Postconditions:**

- Il numero è in whitelist (passa normalmente, RF-5) oppure in blacklist (sempre rifiutato, RF-6).
- La decisione è persistita in locale e applicata immediatamente ai successivi screening.

---

## UC-07 — Gestire whitelist, blacklist e profilo del numero

**Actor:** Utente
**Preconditions:**
- L'utente è nella vista whitelist/blacklist o nel dettaglio di una voce di cronologia / risposta SMS.

**Story:**

As an **Utente**, I want to aggiungere, rimuovere e modificare i numeri in whitelist/blacklist (nome, note, categoria, data di aggiunta) so that le mie decisioni restano corrette nel tempo.

**Main Flow:**

1. L'utente aggiunge un numero (manuale o da cronologia/SMS), lo rimuove da una lista, lo sposta da una lista all'altra, oppure ne modifica il profilo (nome, note, categoria).
2. L'app valida il numero e salva la modifica nello storage locale, registrando la data di aggiunta/ultima modifica.
3. L'app conferma la modifica e indica l'effetto immediato sullo screening ("Da ora questo numero squillerà normalmente" / "Da ora sarà sempre rifiutato").

**Unhappy Paths:**

- Numero già presente nell'altra lista → l'app chiede conferma per lo spostamento invece di duplicarlo.
- Numero in formato non valido → l'app rifiuta il salvataggio segnalando il campo errato; nessuna voce parziale.
- Rimozione accidentale → l'utente può re-inserire il numero; la cronologia dei tentativi resta comunque conservata (la rimozione dalla lista non cancella la cronologia).

**Postconditions:**

- Whitelist e blacklist sono aggiornate, persistite in locale e sopravvivono al riavvio.
- Le decisioni aggiornano immediatamente il comportamento di UC-02 (RF-10); per la blacklist vale anche la configurazione "invia/non inviare SMS" (RF-6).

---

## UC-08 — Configurare il testo dell'SMS automatico

**Actor:** Utente
**Preconditions:**
- L'utente apre le impostazioni dell'app; è presente il testo di default precompilato.

**Story:**

As an **Utente**, I want to modificare il messaggio automatico partendo dal default so that chi viene rifiutato riceve un testo nel mio tono ma sempre con la richiesta di identificarsi.

**Main Flow:**

1. L'utente apre "Testo SMS automatico" e vede il default precompilato.
2. L'utente modifica il testo e salva.
3. L'app valida (non vuoto, lunghezza entro il limite SMS/multi-SMS dichiarato) e conferma; dal successivo rifiuto, UC-04 usa il nuovo testo.

**Unhappy Paths:**

- Testo vuoto o oltre il limite → salvataggio rifiutato con messaggio specifico; resta in vigore il testo precedente.
- Ripristino richiesto → l'utente può tornare al default con un'azione "Ripristina default" senza doverlo ridigitare.

**Postconditions:**

- Il testo personalizzato è salvato in locale e usato da tutti i successivi invii automatici.
- Il default originale resta disponibile come opzione di ripristino.

---

## Traceability Matrix

| UC ID | Title | UN Trace / RF |
|---|---|---|
| UC-01 | Attivare la protezione anti-sconosciuti | RF-1 (prerequisito operativo: ruolo + permessi) |
| UC-02 | Rifiutare automaticamente una chiamata sconosciuta | RF-1, RF-2, RF-5, RF-6, RF-10 |
| UC-03 | Registrare il tentativo rifiutato in cronologia | RF-3 |
| UC-04 | Inviare l'SMS automatico al numero rifiutato | RF-4, RF-6 (eccezione blacklist senza SMS) |
| UC-05 | Consultare la cronologia delle chiamate bloccate | RF-3 |
| UC-06 | Classificare un numero dalla risposta SMS (Accetta / Rifiuta) | RF-7, RF-10 |
| UC-07 | Gestire whitelist, blacklist e profilo del numero | RF-8, RF-5, RF-6, RF-10 |
| UC-08 | Configurare il testo dell'SMS automatico | RF-9, RF-4 |

---

*End of Document — CG-UC-001 v0.1.0*
*Next in package: CG-UN-001 — User Needs*
