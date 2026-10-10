# Call Guard — Service Overview

**Document ID:** CG-OVW-001
**Version:** 0.1.0
**Date:** 2026-10-10
**Status:** Draft

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Aldo (PM) | 2026-10-10 | |
| Reviewer | | | |
| Approver | | | |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft for Call Guard |

---

## Table of Contents

1. [General Project Context](#1-general-project-context)
2. [Clinical Significance & Regulatory Qualification](#2-clinical-significance--regulatory-qualification)
3. [Actors & Stakeholders](#3-actors--stakeholders)
4. [Scope Definition](#4-scope-definition)
5. [Design Guidelines](#5-design-guidelines)
6. [Assumptions](#6-assumptions)
7. [Constraints](#7-constraints)
8. [Open Decisions & Residual Questions](#8-open-decisions--residual-questions)

---

## 1. General Project Context

Call Guard è un'app Android standalone che filtra automaticamente le chiamate da numeri sconosciuti: intercetta ogni chiamata in ingresso prima che squilli, rifiuta quelle con numero visibile non presente in rubrica né in whitelist, registra il tentativo in una cronologia locale in-app e invia al chiamante un SMS automatico configurabile che chiede di identificarsi via SMS. All'apertura dell'app, le risposte SMS ricevute vengono mostrate in una vista dedicata con azioni rapide Accetta (whitelist) / Rifiuta (blacklist), che aggiornano immediatamente il comportamento del filtro.

Utente concreto: il proprietario di uno smartphone Android (10+) che riceve chiamate indesiderate o ambigue da numeri non in rubrica e vuole non essere disturbato, mantenere traccia dei tentativi e decidere in un tap chi può richiamare.

Beneficio misurabile: zero squilli da numeri sconosciuti non autorizzati; ogni tentativo rifiutato è tracciato (numero, data/ora, esito, stato SMS, note) e ogni risposta del chiamante è classificabile in meno di 3 tap; nessun dato lascia il dispositivo.

Non esistono prodotti consumatori esterni: l'unico consumatore è l'utente installato sul proprio dispositivo. Non esiste backend, cloud o sincronizzazione multi-dispositivo.

---

## 2. Clinical Significance & Regulatory Qualification

Questa sezione è mantenuta per struttura documentale ma **non applicabile in senso clinico**: Call Guard non è un dispositivo medico e non tratta dati sanitari.

### 2.1 Nature of Data Managed

Call Guard gestisce esclusivamente dati di telefonia personale su singolo dispositivo:

- Numeri di telefono chiamanti (visibili, non in rubrica), qualificati come PII.
- Metadati del tentativo: data/ora, esito (rifiutata / passante), stato invio SMS, note utente.
- Liste gestite dall'utente: rubrica di sistema (sola lettura per il confronto), whitelist e blacklist con profilo del numero (nome, note, categoria, data di aggiunta).
- Contenuti SMS: testo automatico configurabile in uscita (default sotto) e risposte SMS in ingresso mostrate all'apertura dell'app.

Il servizio non genera, non trasforma e non inferisce alcuna informazione clinica. Non esegue scoring, classificazione automatica di spam o diagnosi di alcun tipo: ogni decisione di whitelist/blacklist è esplicita e manuale dell'utente.

Testo SMS di default: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."

### 2.2 User Safety Obligation

Pur non essendo un servizio safety-critical, un malfunzionamento causa danni concreti all'utente:

- Falso positivo (rifiuto di una chiamata importante): il chiamante legittimo non raggiungibile riceve comunque l'SMS con richiesta di identificarsi, e il tentativo resta in cronologia con possibilità di promozione immediata in whitelist.
- Falso negativo (mancato rifiuto di spam): squillo indesiderato; mitigato dal rifiuto deterministico su numero visibile non in rubrica/whitelist.
- Perdita di tracciabilità: ogni chiamata rifiutata deve essere registrata anche se l'invio SMS fallisce (stato SMS = fallito, tentativo comunque storicizzato).

Controlli tecnici non negoziabili:

| Control | Implementation |
|---|---|
| Precedenza deterministica delle liste | Ordine fisso: blacklist > whitelist/rubrica > rifiuto di default; le decisioni RF-10 si applicano immediatamente senza riavvio |
| Registrazione prima/durante l'azione | Il tentativo è persistito in locale con esito e stato SMS; nessun flusso termina senza scrittura in cronologia |
| Nessun PII nei log | Log tecnici senza numeri di telefono completi né contenuti SMS; numeri solo nello storage cifrato locale dell'app |
| Fail-open trasparente | Se screening o SMS falliscono (timeout di piattaforma, rete carrier), la chiamata non viene persa in silenzio: esito e stato SMS riflettono il fallimento in lista |

> **Mandatory principle:** Nessun dato telefonico lascia il dispositivo. Qualsiasi richiesta futura di cloud, analytics remota, sincronizzazione o scoring automatico richiede una Change Request e una nuova valutazione privacy/Play Policy prima di qualsiasi progettazione.

### 2.3 Regulatory Qualification

Call Guard non è un MDSW, non rientra nel campo di EU MDR né FDA 21 CFR 820 e non applica IEC 62304 / ISO 13485 / ISO 14971.

Quadro regolatorio applicabile:

- **Google Play Policy (permessi sensibili):** SEND_SMS e RECEIVE_SMS sono permessi restricted e richiedono dichiarazione d'uso core e giustificazione in fase di pubblicazione; rischio concreto di rifiuto in review.
- **Privacy (GDPR / ePrivacy, ove applicabile):** i numeri di telefono sono dati personali; base giuridica e consenso all'accesso a telefono, rubrica e SMS gestiti via permessi runtime Android e ruoli di sistema; conservazione solo locale, senza trasferimento a terzi.
- **Piattaforma Android:** uso del ruolo ROLE_CALL_SCREENING e di CallScreeningService secondo le API supportate su Android 10+.

---

## 3. Actors & Stakeholders

### 3.1 Utente proprietario del dispositivo

**Description:** Proprietario dello smartphone Android che installa, configura e usa Call Guard. Assegna il ruolo di call screening, configura il testo SMS, consulta cronologia e risposte, gestisce whitelist/blacklist.

**Access Scope:** Pieno controllo locale: lettura/scrittura su cronologia, liste, profilo numeri e template SMS; concessione/revoca dei permessi runtime di sistema.

**Key interactions:**
- Assegna all'app il ruolo di call screening e concede permessi telefono/contatti/SMS.
- Personalizza il testo dell'SMS automatico (RF-9).
- Consulta la lista tentativi rifiutati con numero, data/ora, esito, stato SMS, note (RF-3).
- Classifica i numeri dalle risposte SMS con Accetta (whitelist) / Rifiuta (blacklist) (RF-7).
- Aggiunge, rimuove e modifica whitelist/blacklist e profili numero (RF-8).

---

### 3.2 Chiamante sconosciuto

**Description:** Soggetto esterno che chiama da numero visibile non presente in rubrica né in whitelist. Non interagisce direttamente con la UI dell'app.

**Access Scope:** Nessun accesso all'app; riceve solo l'SMS automatico e può rispondere via SMS.

**Key interactions:**
- Effettua la chiamata in ingresso intercettata e potenzialmente rifiutata (RF-1, RF-2).
- Riceve l'SMS automatico di richiesta identificazione (RF-4).
- Invia un SMS di risposta con le proprie informazioni, mostrato all'utente all'apertura dell'app (RF-7).

---

### 3.3 Sistema operativo Android e carrier

**Description:** Piattaforma che fornisce call screening, gestione telefonia/SMS e connettività carrier. Include CallScreeningService, ruolo ROLE_CALL_SCREENING, provider SMS e rubrica di sistema.

**Access Scope:** Permessi di sistema concessi dall'utente: lettura stato telefono e rubrica, screening/rifiuto chiamate, invio/ricezione SMS, persistenza locale.

**Key interactions:**
- Notifica la chiamata in ingresso al modulo nativo prima della suoneria entro il timeout di piattaforma (RF-1).
- Esegue disconnessione/silenziamento su comando dell'app (RF-2, RF-6).
- Recapita l'SMS automatico e gli SMS di risposta secondo disponibilità di rete/carrier (RF-4, RF-7).

---

### 3.4 Google Play Review (stakeholder esterno)

**Description:** Processo di revisione dello store che autorizza o nega la pubblicazione in presenza di permessi SMS/telefono restricted.

**Key interactions:** Valutazione della dichiarazione d'uso core di SEND_SMS / RECEIVE_SMS; possibile richiesta di video dimostrativo, policy privacy e riduzione dei permessi.

---

## 4. Scope Definition

### 4.1 In Scope

| Capability | Description |
|---|---|
| Intercettazione pre-squillo (RF-1) | Modulo nativo Kotlin con CallScreeningService intercetta ogni chiamata in ingresso prima della suoneria, entro il timeout di piattaforma |
| Rifiuto automatico sconosciuti (RF-2) | Se il numero è visibile e non è in rubrica né in whitelist, la chiamata è disconnessa/silenziata automaticamente |
| Cronologia tentativi (RF-3) | Ogni chiamata rifiutata è registrata in lista in-app con numero, data/ora, esito, stato SMS inviato, note; la lista sopravvive al riavvio |
| SMS automatico configurabile (RF-4, RF-9) | Invio automatico di SMS al numero rifiutato con testo modificabile in-app e default precompilato (vedi §2.1) |
| Whitelist pass-through (RF-5, RF-10) | I numeri in whitelist (e in rubrica) passano normalmente e l'aggiornamento della lista ha effetto immediato |
| Blacklist enforcement (RF-6, RF-10) | I numeri in blacklist sono sempre rifiutati, con invio SMS secondo configurazione, a effetto immediato |
| Vista risposte SMS con CTA (RF-7) | All'apertura dell'app gli SMS in ingresso sono intercettati e mostrati con CTA Accetta (whitelist) / Rifiuta (blacklist) |
| Gestione liste e profili (RF-8) | Aggiunta, rimozione e modifica del profilo numero (nome, note, categoria, data di aggiunta) per whitelist e blacklist |
| UI Flutter + bridge nativo | UI in Flutter; dialogo col modulo Kotlin via platform channel per screening, invio/lettura SMS e lettura rubrica |
| Persistenza locale | Cronologia, liste, profili e template SMS salvati on-device e disponibili dopo il riavvio |

### 4.2 Out of Scope

| Exclusion | Reason |
|---|---|
| iOS e altre piattaforme | iOS non consente intercettazione a runtime né invio/lettura automatica di SMS; solo blocchi statici via Call Directory — fuori perimetro dichiarato |
| Cloud / backend / sincronizzazione multi-dispositivo | Scelta architetturale privacy-first: nessun dato lascia il dispositivo in questa fase |
| Chiamate in uscita | Non filtrate né registrate; il brief copre solo le chiamate in ingresso |
| Scoring spam / classificazione automatica | Nessuna inferenza automatica; solo decisioni manuali whitelist/blacklist per restare semplici e conformi |
| Numeri anonimi/nascosti | RF-2 si applica solo a numero visibile; la gestione degli anonimi non è definita nel brief |

---

## 5. Design Guidelines

| # | Principle | Rationale |
|---|---|---|
| P-01 | Core telefonico in Kotlin nativo, UI in Flutter | Solo CallScreeningService + ROLE_CALL_SCREENING su Android 10+ può intercettare/rifiutare prima dello squillo; Flutter non ha accesso diretto a queste API e dialoga via platform channel |
| P-02 | Risposta di screening entro il timeout di piattaforma | L'intercettazione non deve ritardare la suoneria oltre i limiti di sistema; il percorso nativo è minimale e senza I/O bloccante |
| P-03 | Solo locale, nessun PII nei log | Numeri e contenuti SMS restano on-device; log tecnici senza numeri completi né testi SMS per privacy e conformità GDPR |
| P-04 | Precedenza liste deterministica e immediata | blacklist > whitelist/rubrica > rifiuto di default; ogni modifica si applica subito senza riavvio per garantire RF-10 |
| P-05 | Registra sempre, anche in caso di errore SMS | La cronologia è la verità operativa; un fallimento di invio SMS non cancella mai il tentativo registrato |
| P-06 | Nessun allargamento scope senza Change Request | Modifiche al perimetro (iOS, cloud, scoring) richiedono gate formale; i gate si aprono con approvazioni, non con retorica |

---

## 6. Assumptions

| # | Assumption | Impact if False |
|---|---|---|
| A-01 | Il numero chiamante da filtrare è visibile (non anonimo) | Serve una decisione di prodotto dedicata per anonimi/nascosti (attualmente fuori scope) |
| A-02 | L'utente assegna il ruolo di call screening e concede permessi telefono, contatti e SMS | Senza ruolo/permessi il filtro non opera; serve onboarding guidato e stato di degradazione esplicito in UI |
| A-03 | La rubrica di sistema è leggibile on-device per il confronto RF-2/RF-5 | Serve un meccanismo alternativo di whitelist esplicita e migrazione dei contatti rilevanti |
| A-04 | Il carrier consente invio/ricezione SMS dal dispositivo nelle condizioni d'uso tipiche | L'SMS automatico diventa best-effort con stato fallito visibile; va valutata la comunicazione di fallback in UI |
| A-05 | Singolo profilo/dispositivo, nessuna sincronizzazione richiesta | Qualsiasi richiesta multi-dispositivo riapre architettura, privacy e modello dati |
| A-06 | La lettura degli SMS di risposta all'apertura dell'app è sufficiente (nessun monitoraggio in background) | Serve un receiver in background con implicazioni su batteria, permessi e Play Policy |

---

## 7. Constraints

| # | Constraint | Source |
|---|---|---|
| C-01 | Android-only, Android 10+ con CallScreeningService e ROLE_CALL_SCREENING | Brief di progetto / vincoli di piattaforma |
| C-02 | Modulo nativo in Kotlin per screening/rifiuto; UI in Flutter via platform channel | Brief di progetto / limiti tecnici Flutter |
| C-03 | SEND_SMS e RECEIVE_SMS sono permessi restricted su Google Play e richiedono giustificazione d'uso core | Google Play Policy — rischio di pubblicazione |
| C-04 | Nessun dato telefonico lascia il dispositivo; persistenza solo locale con sopravvivenza al riavvio | Brief (privacy) + requisiti non funzionali |
| C-05 | Screening deve rispondere entro il timeout di piattaforma senza ritardare la suoneria | Requisiti non funzionali / limiti Android |
| C-06 | Template SMS modificabile con default precompilato obbligatorio (vedi §2.1) | RF-4 / RF-9 del brief |
| C-07 | iOS escluso: nessuna intercettazione runtime né SMS automatici possibili | Brief / limiti piattaforma Apple |

---

## 8. Open Decisions & Residual Questions

### 8.1 Decisions Made

| ID | Question | Decision | Rationale |
|---|---|---|---|
| D-01 | Stack nativo vs cross-platform puro per il filtro? | Core telefonico nativo Kotlin + UI Flutter con platform channel | Solo il nativo può fare call screening pre-squillo; Flutter copre la UI più velocemente |
| D-02 | Quando mostrare le risposte SMS? | Intercettazione e visualizzazione all'apertura dell'app, non in background continuo | Come da brief RF-7; minimizza batteria, permessi e superficie Play Policy |
| D-03 | I numeri in blacklist ricevono comunque l'SMS automatico? | Sì/no secondo configurazione utente (default: nessun SMS per blacklist) | Evita di incentivare risposte da spammer noti; resta configurabile per casi di falso positivo |

### 8.2 Residual Questions & Open Decisions

| ID | Question | Owner | Target Date | Status |
|---|---|---|---|---|
| Q-01 | Strategia di approvazione Play per SEND_SMS/RECEIVE_SMS (dichiarazione d'uso core, video demo, policy privacy)? | Aldo (PM) | 2026-10-24 | Open |
| Q-02 | Comportamento atteso su dual-SIM, numeri anonimi/nascosti e chiamate VoIP/operatori particolari? | Aldo (PM) | 2026-10-24 | Open |
| Q-03 | Default di configurazione per SMS su blacklist e gestione dei fallimenti di invio (retry, stato, notifica)? | Aldo (PM) | 2026-10-24 | Open |
| Q-04 | Periodo di retention di cronologia e SMS e regola di cancellazione manuale/automatica? | Aldo (PM) | 2026-10-24 | Open |
| Q-05 | Testo SMS di default già definitivo o soggetto a revisione legale/UX prima dell'approvazione? | Aldo (PM) | 2026-10-24 | Open |

### 8.3 Future Considerations

> **Spam scoring e blocco predittivo — Out of Scope for this phase.**
> Valutabile solo dopo il tracer-bullet base; richiede dataset, valutazione privacy/GDPR e rivalutazione Play Policy prima di qualsiasi design.

> **Backup/ripristino e sincronizzazione — Out of Scope for this phase.**
> Richiede backend/cifratura E2E e modello di consenso esplicito; oggi esplicitamente escluso dal brief.

> **Porting iOS con Call Directory statica — Out of Scope for this phase.**
> iOS non supporta il flusso runtime di Call Guard; eventuale porting sarebbe un prodotto diverso con scope ridotto.

---

*End of Document — CG-OVW-001 v0.1.0*
*Next in package: CG-UC-001 — Use Cases*
