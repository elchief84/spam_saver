# Call Guard — User Needs

**Document ID:** CG-UN-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Last Updated:** 2026-10-10
**Trace Parent:** CG-UC-001

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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft per brief Call Guard (RF-1–RF-10, vincoli Android) |

---

## Document Scope

Questo documento raccoglie le User Needs (UN) di Call Guard, app Android che protegge il proprietario del dispositivo dalle chiamate da numeri sconosciuti: rifiuto automatico prima dello squillo, registrazione del tentativo, risposta automatica via SMS configurabile e classificazione rapida (whitelist/blacklist) delle risposte ricevute.

Le User Needs descrivono intenzioni, aspettative e vincoli degli stakeholder prima di qualsiasi soluzione tecnica. Ogni need è tracciata verso uno o più Use Cases e sarà decomposta in Software Requirements testabili nella fase successiva. Fonte: brief di progetto Call Guard (obiettivo, problema, ambito, RF-1–RF-10, NFR, vincoli di piattaforma, fuori perimetro, rischi/compliance).

Stakeholder principali: utente proprietario del dispositivo (unico utente operativo), chiamante sconosciuto (numero visibile, non in rubrica), sistema operativo Android (ruolo di call screening, permessi SMS).

---

## UN-101 — Rifiuto automatico dei numeri sconosciuti prima dello squillo

**Text:** Il proprietario del dispositivo deve poter far rifiutare automaticamente ogni chiamata in ingresso da numero visibile non presente in rubrica né in whitelist, prima che il telefono squilli, così da non essere disturbato da chiamate indesiderate o ambigue.

**Note:** Il bisogno vale solo per numeri visibili e identificabili; i numeri anonimi/bloccati non devono attivare invii SMS (manca il destinatario). Il rifiuto non deve ritardare la suoneria delle chiamate legittime oltre i limiti di sistema. Fuori perimetro: chiamate in uscita, iOS e altre piattaforme.

**Tags:** `Operator-Workflow`, `Performance`, `Architecture-Constraint`
**Trace UC:** UC-01, UC-02

---

## UN-102 — Traccia consultabile dei tentativi rifiutati

**Text:** Il proprietario del dispositivo deve poter consultare una lista in-app di ogni chiamata rifiutata con numero, data/ora, esito e stato dell'SMS inviato, così da avere una traccia affidabile di chi ha tentato di contattarlo.

**Note:** La lista è la memoria operativa dell'utente: deve restare leggibile al crescere dei record e sopravvivere al riavvio del dispositivo. I numeri sono dati personali: nessun dato lascia il dispositivo e nessun identificativo completo finisce nei log operativi.

**Tags:** `Operator-Workflow`, `Data-Retention`, `Offline-Support`, `Privacy`
**Trace UC:** UC-03

---

## UN-103 — Risposta automatica via SMS con testo configurabile

**Text:** Il proprietario del dispositivo deve poter far inviare automaticamente un SMS al numero rifiutato con un testo da lui configurato, così che il chiamante legittimo sappia come identificarsi.

**Note:** Testo di default precompilato: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione." L'utente deve poter modificare il testo in-app in qualsiasi momento. Per i numeri in blacklist l'invio segue la configurazione (può essere disattivato). L'invio richiede consenso/permessi SMS e impatta la pubblicabilità su Google Play (permessi restricted): il bisogno include una giustificazione chiara all'utente.

**Tags:** `Operator-Workflow`, `Configurability`, `Compliance`
**Trace UC:** UC-04

---

## UN-104 — I numeri fidati devono sempre passare

**Text:** Il proprietario del dispositivo deve poter marcare numeri fidati in whitelist in modo che le loro chiamate passino sempre normalmente, così da non perdere mai chiamate attese da contatti noti o promossi.

**Note:** La whitelist si aggiunge alla rubrica come insieme dei numeri "che passano": un numero in whitelist non viene mai rifiutato (RF-5). La promozione da risposta SMS a whitelist deve essere un'azione rapida (una CTA).

**Tags:** `Operator-Workflow`, `Access-Control`
**Trace UC:** UC-05, UC-06

---

## UN-105 — I numeri indesiderati devono essere sempre bloccati

**Text:** Il proprietario del dispositivo deve poter marcare numeri indesiderati in blacklist in modo che le loro chiamate siano sempre rifiutate, così da bloccare stabilmente seccatori e chiamate indesiderate ricorrenti.

**Note:** La blacklist ha precedenza: un numero in blacklist viene rifiutato anche se il filtro generico fosse disattivato, e l'invio dell'SMS segue la configurazione (di default disattivabile per non dare corda allo spammer). La retrocessione in blacklist deve essere un'azione rapida (una CTA).

**Tags:** `Operator-Workflow`, `Access-Control`
**Trace UC:** UC-05, UC-06

---

## UN-106 — Classificazione rapida delle risposte SMS all'apertura dell'app

**Text:** Il proprietario del dispositivo deve poter vedere all'apertura dell'app gli SMS di risposta ricevuti dai numeri rifiutati, con azioni rapide "Accetta (whitelist)" e "Rifiuta (blacklist)", così da promuovere o bandire un numero in pochi secondi in base a come si presenta.

**Note:** L'intercettazione degli SMS avviene all'apertura dell'app (non in background permanente) per perimetro approvato. La vista deve mostrare numero, contenuto e contesto della chiamata originaria. Dopo la decisione il numero non deve più comparire come "da classificare".

**Tags:** `Operator-Workflow`, `Configurability`
**Trace UC:** UC-06

---

## UN-107 — Gestione di whitelist, blacklist e profilo del numero

**Text:** Il proprietario del dispositivo deve poter gestire whitelist e blacklist (aggiunta, rimozione, modifica del profilo del numero con nome, note, categoria e data di aggiunta), così da mantenere nel tempo un filtro accurato e documentato.

**Note:** Il profilo (nome, note, categoria, data di aggiunta) serve a ricordare perché un numero è stato promosso o bandito. La rimozione da una lista deve ripristinare il comportamento di default del filtro (rifiuto + SMS per gli sconosciuti). Le liste persistono al riavvio.

**Tags:** `Operator-Workflow`, `Data-Retention`, `Configurability`
**Trace UC:** UC-07

---

## UN-108 — Personalizzazione del testo SMS automatico

**Text:** Il proprietario del dispositivo deve poter modificare in-app il testo dell'SMS automatico partendo dal default precompilato, così da adattare tono e informazioni richieste al proprio uso.

**Note:** L'editor deve mostrare sempre il default come base di partenza e consentire il ripristino del default. Nessuna competenza tecnica richiesta: campo di testo singolo con salvataggio immediato.

**Tags:** `Configurability`, `Operator-Workflow`
**Trace UC:** UC-04

---

## UN-109 — Effetto immediato delle decisioni

**Text:** Il proprietario del dispositivo deve poter contare sul fatto che ogni decisione di whitelist/blacklist cambi immediatamente il comportamento del filtro sulle chiamate successive, così da fidarsi che il sistema faccia ciò che ha appena ordinato.

**Note:** Non è accettabile un ritardo di "sincronizzazione" o un riavvio per applicare la decisione: la chiamata successiva dallo stesso numero deve già seguire la nuova regola. Vale anche per la modifica del testo SMS (applicata al successivo rifiuto).

**Tags:** `Operator-Workflow`, `Performance`
**Trace UC:** UC-05, UC-06, UC-07

---

## UN-110 — Privacy locale e assenza di cloud

**Text:** Il sistema deve trattare tutti i numeri di telefono e gli SMS esclusivamente sul dispositivo senza trasmetterli a server esterni, così che la protezione antispam non crei un nuovo rischio privacy.

**Note:** I numeri sono PII sotto GDPR: nessun dato lascia il dispositivo, nessuna sincronizzazione multi-dispositivo (fuori perimetro per scelta). Il consenso ai permessi telefono/SMS/call-screening deve essere esplicito e revocabile; la revoca riporta l'app a un comportamento trasparente (nessun filtro silenzioso).

**Tags:** `Privacy`, `Security`, `GDPR`, `Architecture-Constraint`
**Trace UC:** UC-01, UC-03, UC-04, UC-06, UC-07

---

## UN-111 — Affidabilità entro i limiti di piattaforma e gestione trasparente degli errori

**Text:** Il sistema deve completare la decisione di screening entro il timeout imposto da Android e, quando non può rifiutare, inviare l'SMS o registrare il tentativo, informare l'utente in modo comprensibile senza esporre dettagli interni, così che i guasti restino rari, visibili e diagnosticabili.

**Note:** Include: risposta al call screening entro il timeout di piattaforma (mai bloccare la suoneria legittima), requisiti Android 10+ e ruolo di call screening assegnato dall'utente, comportamento definito in assenza di segnale/carrier anomalo. Errori mostrati con messaggi strutturati e azionabili; log operativi strutturati e tracciabili senza PII (numeri anonimizzati, identificativi completi solo in archivi controllati on-device).

**Tags:** `Performance`, `Architecture-Constraint`, `Observability`, `Logging`, `Privacy`, `Error-Handling`
**Trace UC:** UC-01, UC-02, UC-03, UC-04

---

## Traceability Matrix

| UN ID | Summary | UC Trace |
|---|---|---|
| UN-101 | Rifiuto automatico sconosciuti prima dello squillo | UC-01, UC-02 |
| UN-102 | Lista in-app dei tentativi rifiutati | UC-03 |
| UN-103 | SMS automatico al numero rifiutato (configurabile) | UC-04 |
| UN-104 | Whitelist: i fidati passano sempre | UC-05, UC-06 |
| UN-105 | Blacklist: gli indesiderati sempre rifiutati | UC-05, UC-06 |
| UN-106 | Classificazione rapida SMS all'apertura app | UC-06 |
| UN-107 | Gestione liste + profilo numero | UC-07 |
| UN-108 | Personalizzazione testo SMS con default | UC-04 |
| UN-109 | Effetto immediato delle decisioni | UC-05, UC-06, UC-07 |
| UN-110 | Privacy locale, nessun cloud, consenso | UC-01, UC-03, UC-04, UC-06, UC-07 |
| UN-111 | Affidabilità nei limiti Android + errori/log senza PII | UC-01, UC-02, UC-03, UC-04 |

---

*End of Document — CG-UN-001 v0.1.0*
*Next in package: CG-RSK-001 — Risk Analysis*
