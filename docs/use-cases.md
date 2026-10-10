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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft da brief Call Guard (RF-1–RF-10) |

---

## Document Scope

Questo documento definisce gli Use Cases di Call Guard, app Android che filtra le chiamate da numeri sconosciuti: rifiuta automaticamente le chiamate con numero visibile non in rubrica/whitelist, registra ogni tentativo, invia un SMS automatico configurabile e permette di classificare rapidamente i numeri (whitelist/blacklist) dalle risposte ricevute.

Livello di astrazione: descrive *cosa* ogni attore vuole ottenere e *perché*, non come il sistema lo implementa internamente.

Documento padre: overview di prodotto (CG-OVW-001). Prossimo documento nel pacchetto: User Needs.

Fuori perimetro (non coperto dagli UC): iOS e altre piattaforme, cloud/backend e sincronizzazione multi-dispositivo, chiamate in uscita.

---

## Actor Definitions

| Actor | Description |
|---|---|
| Utente proprietario | Persona che possiede il dispositivo Android, configura Call Guard, consulta il registro e classifica i numeri. È l'unico beneficiario diretto. |
| Chiamante sconosciuto | Persona o sistema che chiama da un numero visibile non presente in rubrica né in whitelist. Non interagisce con la UI; riceve il rifiuto e l'SMS automatico. |
| Sistema operativo Android | Piattaforma Android 10+ nel ruolo di call screening (ROLE_CALL_SCREENING) e nei permessi SMS/telefono. Invoca l'app a ogni chiamata/SMS in ingresso ed esegue il rifiuto. |

---

## UC-01 — Rifiutare automaticamente chiamata da numero sconosciuto

**Actor:** Sistema operativo Android (su configurazione dell'Utente proprietario)
**Preconditions:**
- L'utente ha assegnato a Call Guard il ruolo di call screening e concesso i permessi telefono richiesti.
- La whitelist e la blacklist persistite sono leggibili all'arrivo della chiamata.
- La chiamata in ingresso ha un numero chiamante visibile (non anonimo/nascosto).

**Story:**
Come **Utente proprietario**, voglio che le chiamate dai numeri che non conosco non mi facciano squillare il telefono, così non vengo interrotto da chiamate indesiderate o ambigue e ritrovo comunque traccia di ogni tentativo.

**Main Flow:**
1. Il sistema operativo notifica a Call Guard una chiamata in ingresso prima della suoneria, con numero chiamante e orario.
2. Call Guard verifica nell'ordine: numero nascosto → lascia passare; numero in rubrica o in whitelist → lascia passare (RF-5); numero in blacklist → rifiuta sempre (RF-6); altrimenti numero visibile non noto → rifiuta (RF-2).
3. Call Guard risponde entro il timeout di piattaforma (disconnessione/silenziamento) senza far squillare il telefono.
4. Call Guard registra il tentativo con numero, data/ora, esito "rifiutata" e passa il controllo a UC-02/UC-03.

**Unhappy Paths:**
- Numero anonimo o non presentabile → la chiamata passa normalmente; nessuna registrazione come "rifiutata".
- Timeout di screening imminente o liste non leggibili → fail-open: la chiamata passa per non sopprimere chiamate legittime; l'evento è registrato come "non filtrata per errore".
- Contatto aggiunto in rubrica dopo un rifiuto → i rifiuti precedenti restano in cronologia; solo le nuove chiamate passano (RF-10).

**Postconditions:**
- La chiamata indesiderata non ha interrotto l'utente.
- L'evento è disponibile nel registro in-app (UC-02) e attiva l'invio SMS (UC-03) salvo configurazione blacklist.

---

## UC-02 — Consultare registro chiamate rifiutate

**Actor:** Utente proprietario
**Preconditions:**
- L'utente ha aperto l'app.
- Esiste almeno una chiamata intercettata oppure la lista è vuota (stato vuoto gestito).

**Story:**
Come **Utente proprietario**, voglio vedere l'elenco dei tentativi rifiutati con numero, data/ora, esito e stato SMS, così capisco chi mi ha cercato e decido se richiamare, classificare o ignorare.

**Main Flow:**
1. L'utente apre la vista "Chiamate rifiutate".
2. Il sistema mostra la lista in ordine cronologico inverso: numero, data/ora, esito (rifiutata / non filtrata per errore), stato SMS inviato/non inviato, note se presenti.
3. L'utente seleziona una voce per vedere il dettaglio completo e le azioni disponibili (vai a UC-05/UC-06/UC-07/UC-08).

**Unhappy Paths:**
- Nessun tentativo registrato → il sistema mostra uno stato vuoto esplicativo, non una lista bianca ambigua.
- Dati persistiti danneggiati o illeggibili dopo riavvio → il sistema mostra errore di lettura e non perde gli altri record integri.

**Postconditions:**
- L'utente ha una traccia consultabile e persistente al riavvio di ogni tentativo.
- Nessun PII viene scritto nei log di diagnostica.

---

## UC-03 — Inviare SMS automatico al numero rifiutato

**Actor:** Sistema operativo Android (permessi SMS), su regola dell'Utente proprietario
**Preconditions:**
- La chiamata è stata rifiutata in UC-01.
- Il permesso SEND_SMS è concesso e il numero di destinazione è un mobile valido che accetta SMS.
- Il testo SMS configurato esiste (default precompilato se l'utente non l'ha mai modificato).

**Story:**
Come **Utente proprietario**, voglio che ogni chiamante sconosciuto rifiutato riceva subito un SMS che gli chiede di identificarsi via SMS, così i contatti legittimi hanno un canale per farsi riconoscere senza richiamarmi a vuoto.

**Main Flow:**
1. Dopo il rifiuto, il sistema recupera il testo SMS configurato (default: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione.").
2. Il sistema invia l'SMS al numero rifiutato, salvo regola blacklist: per i numeri in blacklist l'invio segue la configurazione (default: non inviare).
3. Il sistema aggiorna la voce di registro con stato SMS "inviato" o "non previsto da configurazione".

**Unhappy Paths:**
- Permesso SEND_SMS revocato o invio fallito (rete/carrier) → il sistema marca la voce come "SMS non inviato" con motivo e non riprova in loop; l'utente lo vede in UC-02.
- Numero in blacklist con invio disabilitato → nessun SMS inviato; esito registrato come scelta configurata, non come errore.
- Testo SMS vuoto al momento dell'invio → invio bloccato e utente avvisato alla successiva apertura; nessuna registrazione ingannevole di "inviato".

**Postconditions:**
- Il chiamante sconosciuto ha ricevuto la richiesta di identificazione, oppure il registro riporta onestamente perché l'SMS non è partito.
- La cronologia resta coerente tra esito chiamata e stato SMS.

---

## UC-04 — Personalizzare testo SMS automatico

**Actor:** Utente proprietario
**Preconditions:**
- L'utente ha aperto le impostazioni in-app.
- Esiste un testo corrente (default precompilato alla prima installazione).

**Story:**
Come **Utente proprietario**, voglio modificare il testo dell'SMS automatico con il mio tono e le mie istruzioni, così i chiamanti legittimi capiscono cosa scrivere per farsi riconoscere.

**Main Flow:**
1. L'utente apre "Testo SMS automatico" e vede il testo corrente precompilato.
2. L'utente modifica il testo e salva.
3. Il sistema valida (non vuoto, lunghezza entro limite SMS) e applica immediatamente il nuovo testo ai rifiuti successivi.

**Unhappy Paths:**
- Testo vuoto o oltre il limite → il sistema rifiuta il salvataggio indicando il problema; il testo precedente resta attivo.
- Salvataggio interrotto (app chiusa/crash) → alla riapertura il testo è quello dell'ultimo salvataggio valido, mai un testo troncato.

**Postconditions:**
- I nuovi rifiuti (UC-03) usano il testo aggiornato.
- La modifica sopravvive al riavvio.

---

## UC-05 — Classificare risposta SMS con Accetta o Rifiuta

**Actor:** Utente proprietario
**Preconditions:**
- L'utente ha aperto l'app.
- Esiste almeno un SMS in ingresso intercettato e associabile a un numero precedentemente rifiutato (o a un mittente non in rubrica).

**Story:**
Come **Utente proprietario**, voglio leggere le risposte SMS dei chiamanti rifiutati e con un tap promuoverli (whitelist) o bandirli (blacklist), così smetto di filtrare chi si è presentato bene e blocco chi è spam.

**Main Flow:**
1. All'apertura dell'app, il sistema mostra la vista dedicata con gli SMS in ingresso: mittente, data/ora, corpo del messaggio.
2. L'utente legge la presentazione e tocca "Accetta (whitelist)" oppure "Rifiuta (blacklist)".
3. Il sistema sposta il numero nella lista scelta (rimuovendolo dall'altra se presente) e applica subito la nuova regola alle chiamate future (RF-10).

**Unhappy Paths:**
- SMS illeggibile o permesso RECEIVE_SMS mancante → la vista mostra avviso esplicito e nessuna CTA ingannevole.
- Numero già presente nella lista opposta → il sistema lo sposta (ultima decisione vince) e mostra conferma dello spostamento.
- Doppio tap / decisione duplicata → operazione idempotente: nessun duplicato in lista.

**Postconditions:**
- Il numero è in esattamente una lista (o in nessuna se l'utente rimuove la decisione).
- Le chiamate future seguono immediatamente UC-01 con la nuova regola.

---

## UC-06 — Gestire Whitelist

**Actor:** Utente proprietario
**Preconditions:**
- L'utente ha aperto la vista "Whitelist".

**Story:**
Come **Utente proprietario**, voglio decidere quali numeri passano sempre, così clienti, familiari o nuovi contatti verificati mi raggiungono senza più filtri.

**Main Flow:**
1. L'utente visualizza la whitelist (numero, nome, categoria, data di aggiunta).
2. L'utente aggiunge un numero (da registro UC-02, da SMS UC-05 o manuale) oppure rimuove un numero esistente.
3. Il sistema applica subito la regola: i numeri in whitelist non vengono rifiutati (RF-5).

**Unhappy Paths:**
- Aggiunta di numero già in blacklist → il sistema chiede conferma di spostamento; mai doppia presenza.
- Formato numero non valido → il sistema rifiuta l'aggiunta indicando il formato atteso; nessuna voce salvata.
- Rimozione di numero inesistente → nessun errore bloccante; la lista resta invariata.

**Postconditions:**
- La whitelist persistita riflette la scelta e sopravvive al riavvio.
- UC-01 applica immediatamente la nuova regola.

---

## UC-07 — Gestire Blacklist

**Actor:** Utente proprietario
**Preconditions:**
- L'utente ha aperto la vista "Blacklist".
- Esiste l'opzione di configurazione "invia SMS ai numeri in blacklist" (default: disattivata).

**Story:**
Come **Utente proprietario**, voglio bandire i numeri spam o molesti con un tap, così le loro chiamate future vengono sempre rifiutate senza disturbarmi.

**Main Flow:**
1. L'utente visualizza la blacklist (numero, motivo/note, data di aggiunta).
2. L'utente aggiunge un numero (da registro, da SMS o manuale) oppure lo rimuove (sblocco).
3. Il sistema applica subito la regola: i numeri in blacklist vengono sempre rifiutati (RF-6), con o senza SMS secondo configurazione.

**Unhappy Paths:**
- Aggiunta di numero già in whitelist → il sistema chiede conferma di spostamento; mai doppia presenza.
- Formato numero non valido → il sistema rifiuta l'aggiunta; nessuna voce salvata.
- Sblocco di numero mai bandito → nessuna modifica; nessuna conferma ingannevole.

**Postconditions:**
- La blacklist persistita riflette la scelta e sopravvive al riavvio.
- UC-01 e UC-03 applicano immediatamente rifiuto e regola SMS per quel numero.

---

## UC-08 — Modificare profilo numero in lista

**Actor:** Utente proprietario
**Preconditions:**
- Il numero esiste in whitelist, blacklist o nel registro chiamate.

**Story:**
Come **Utente proprietario**, voglio annotare nome, note e categoria su ogni numero, così tra un mese ricordo perché ho accettato o bandito quel numero.

**Main Flow:**
1. L'utente apre il dettaglio del numero da qualsiasi lista.
2. L'utente modifica nome, note, categoria e salva.
3. Il sistema valida e mostra il profilo aggiornato con data di aggiunta invariata.

**Unhappy Paths:**
- Nome/note vuoti o troppo lunghi → il sistema rifiuta il campo specifico senza perdere gli altri campi già compilati.
- Modifica concorrente persa (dettaglio aperto mentre il numero viene spostato di lista in UC-05) → il sistema preserva profilo (nome/note/categoria) durante lo spostamento; l'utente vede dove è finito il numero.

**Postconditions:**
- Il profilo aggiornato è visibile in tutte le viste e persiste al riavvio.
- La classificazione whitelist/blacklist del numero non cambia per effetto della sola modifica del profilo.

---

## UC-09 — Abilitare ruolo call screening e permessi

**Actor:** Utente proprietario
**Preconditions:**
- Dispositivo Android 10+ con SIM e app installata.
- Il ruolo di call screening non è ancora assegnato o un permesso sensibile manca.

**Story:**
Come **Utente proprietario**, voglio essere guidato ad attivare il ruolo di filtro chiamate e i permessi necessari, così il blocco automatico funziona davvero e capisco i rischi privacy/Play Store.

**Main Flow:**
1. L'utente apre Call Guard; il sistema mostra lo stato: ruolo call screening attivo/non attivo, permessi telefono/SMS concessi/mancanti.
2. L'utente tocca "Abilita filtro" e il sistema apre la schermata di sistema per assegnare il ruolo; poi richiede i permessi telefono/SMS con motivazione.
3. Il sistema conferma "protezione attiva" solo quando ruolo + permessi minimi sono presenti; altrimenti resta in stato "non protetto" con azione di completamento.

**Unhappy Paths:**
- Utente nega ruolo o permesso sensibile (SEND_SMS/RECEIVE_SMS) → il sistema degrada onestamente: nessuna promessa di blocco; indica cosa non funzionerà (es. senza SEND_SMS nessun SMS automatico).
- Permesso revocato in seguito da sistema → alla successiva apertura l'app mostra "protezione sospesa" e ripropone l'abilitazione; UC-01 va in fail-open (lascia passare).
- Dispositivo non supportato (< Android 10 o senza ruolo) → il sistema dichiara incompatibilità invece di fingere protezione.

**Postconditions:**
- Lo stato di protezione mostrato corrisponde ai permessi reali.
- L'utente ha dato un consenso informato (PII solo on-device, nessun invio a server).

---

## Traceability Matrix

| UC ID | Title | RF Trace |
|---|---|---|
| UC-01 | Rifiutare automaticamente chiamata da numero sconosciuto | RF-1, RF-2, RF-5, RF-6, RF-10 |
| UC-02 | Consultare registro chiamate rifiutate | RF-3 |
| UC-03 | Inviare SMS automatico al numero rifiutato | RF-4, RF-6 |
| UC-04 | Personalizzare testo SMS automatico | RF-9 |
| UC-05 | Classificare risposta SMS con Accetta o Rifiuta | RF-7, RF-10 |
| UC-06 | Gestire Whitelist | RF-5, RF-8, RF-10 |
| UC-07 | Gestire Blacklist | RF-6, RF-8, RF-10 |
| UC-08 | Modificare profilo numero in lista | RF-8 |
| UC-09 | Abilitare ruolo call screening e permessi | NFR affidabilità/privacy, vincoli piattaforma |

---

*End of Document — CG-UC-001 v0.1.0*
*Next in package: CG-UN-001 — User Needs*
