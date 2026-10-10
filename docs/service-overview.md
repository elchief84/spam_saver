# Call Guard — Service Overview

**Document ID:** CG-OVW-001
**Version:** 0.1.0
**Date:** 2026-10-10
**Status:** Draft

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

Call Guard è un'app Android che protegge l'utente dalle chiamate da numeri sconosciuti. Intercetta ogni chiamata in ingresso prima che squilli: se il numero è visibile ma non è in rubrica né in whitelist, rifiuta automaticamente la chiamata, registra il tentativo in una lista in-app consultabile e invia al chiamante un SMS automatico configurabile che chiede di identificarsi via SMS. All'apertura dell'app, le risposte SMS ricevute vengono mostrate con azioni rapide per promuovere il numero in whitelist o bandirlo in blacklist.

Il valore per l'utente è triplice: filtro automatico (niente squilli da sconosciuti), traccia consultabile (numero, data/ora, esito, stato SMS, note) e classificazione rapida (una tap per accettare/rifiutare un numero in base a come si presenta). Il valore per il business è un'app utility a perimetro stretto, offline-first e senza backend, con rischi concentrati su permessi Android e policy Play.

Non è un prodotto H.Core né un dispositivo medico: non ci sono prodotti consumer clinici, aree terapeutiche o integrazioni cloud. L'unico "consumatore" del servizio di screening è l'app Call Guard stessa (UI Flutter + modulo nativo Kotlin).

User needs principali:

- UN-1 — Come proprietario del telefono, voglio non essere interrotto da numeri sconosciuti in modo da restare concentrato ed evitare spam/scam.
- UN-2 — Come proprietario, voglio vedere chi ha provato a chiamarmi e se l'SMS automatico è partito, in modo da non perdere contatti legittimi.
- UN-3 — Come proprietario, voglio chiedere automaticamente "chi sei?" via SMS senza rispondere a voce, in modo da filtrare senza sforzo.
- UN-4 — Come proprietario, voglio promuovere/bandire un numero con una tap quando leggo la sua risposta, in modo da addestrare il filtro in pochi secondi.

## 2. Clinical Significance & Regulatory Qualification

### 2.1 Nature of Data Managed

Call Guard non gestisce dati clinici. Gestisce dati personali di telecomunicazione, esclusivamente on-device:

- Numeri di telefono chiamanti (PII), visibilità del numero (visibile/nascosto).
- Metadati del tentativo: data/ora, esito (rifiutata/passante), stato invio SMS.
- Contenuto degli SMS: testo auto-inviato configurabile dall'utente e testi di risposta ricevuti dal chiamante.
- Liste utente: rubrica di sistema (sola lettura per il confronto), whitelist/blacklist con profilo numero (nome, note, categoria, data di aggiunta).

Il servizio non genera, trasforma né inferisce informazioni cliniche. Non fa scoring, non classifica spam con modelli, non prende decisioni sanitarie. Esempi rappresentativi: "+39 333 0000000 — 2026-10-10 09:41 — rifiutata — SMS inviato"; "whitelist: +39 333 0000001, nome Mario Rossi, categoria Corriere, aggiunto 2026-10-09".

### 2.2 User Safety Obligation

Pur non essendo SaMD, Call Guard comporta un obbligo di sicurezza per l'utente: un falso positivo (rifiuto di una chiamata legittima urgente — es. medico, scuola, assistenza stradale) può causare danno pratico per mancata reperibilità.

Controlli tecnici non negoziabili:

| Control | Implementation |
|---|---|
| Whitelist sempre passante | Il percorso di screening controlla prima rubrica + whitelist; i numeri presenti non vengono mai rifiutati (RF-5). |
| Nessuna perdita di traccia | Ogni chiamata rifiutata è registrata in lista persistente locale con data/ora ed esito, consultabile anche a telefono riavviato (RF-3). |
| Nessun PII nei log | I log tecnici non contengono numeri di telefono né contenuti SMS; solo contatori/esiti anonimizzati. |
| Fail-open su errore | Se lo screening non riesce a decidere entro il timeout di piattaforma, la chiamata passa normalmente invece di essere bloccata. |

> **Mandatory principle:** Call Guard non blocca mai chiamate senza lasciare traccia locale e non inferisce la natura del chiamante. Qualsiasi evoluzione verso classificazione automatica anti-spam dovrà passare per una revisione di prodotto e privacy prima del disegno.

Non si applica l'analisi dei rischi ISO 14971 clinica; i rischi di prodotto (mancata risposta, policy Play, PII) sono trattati in §4–§8 e nel futuro Risk Log.

### 2.3 Regulatory Qualification

Call Guard non è un dispositivo medico e non rientra nel MDR UE né in FDA 21 CFR 820/QMSR. Non si applica la classificazione IEC 62304 (non-MDSW: nessuna classe A/B/C rivendicata).

Rilevano invece:

- **Privacy (GDPR/ePrivacy):** i numeri di telefono sono dati personali; trattamento solo on-device, senza trasmissione a server terzi; necessaria informativa e base giuridica (legittimo interesse dell'utente a filtrare le proprie chiamate) e cancellazione locale su richiesta (rimozione da cronologia/liste).
- **Policy Google Play:** SEND_SMS e RECEIVE_SMS sono permessi "restricted" e richiedono dichiarazione di core functionality; il ruolo ROLE_CALL_SCREENING richiede consenso esplicito dell'utente. Rischio di rigetto in review Play da gestire come rischio di pubblicazione.
- **Norme telecom nazionali:** l'invio automatico di SMS è consentito come risposta puntuale a una chiamata ricevuta; vietato l'uso per marketing massivo (fuori perimetro in ogni caso).

## 3. Actors & Stakeholders

### 3.1 Utente proprietario del dispositivo

**Description:** Proprietario del telefono Android che installa, configura e usa Call Guard. Unico beneficiario e unico decisore di classificazione.

**Access Scope:** Pieno accesso in-app: cronologia tentativi, vista SMS con CTA, whitelist/blacklist, testo SMS configurabile, impostazioni invio SMS per blacklist.

**Key interactions:**
- Assegna all'app il ruolo di call screening e concede i permessi telefono/SMS/rubrica.
- Configura il testo dell'SMS automatico (default precompilato).
- Consulta la lista dei tentativi rifiutati con dettagli e note.
- Classifica i numeri via CTA Accetta/Rifiuta e gestisce i profili (nome, note, categoria).

### 3.2 Chiamante sconosciuto

**Description:** Persona o sistema che chiama da un numero visibile non presente in rubrica/whitelist. Non è un utente dell'app, è la controparte filtrata.

**Access Scope:** Nessun accesso all'app; riceve solo l'SMS automatico di richiesta identificazione e può rispondere via SMS.

**Key interactions:**
- Effettua la chiamata in ingresso intercettata e rifiutata.
- Riceve l'SMS automatico di richiesta identificazione.
- Invia eventualmente un SMS di risposta con le proprie informazioni identificative.

### 3.3 Sistema operativo Android e carrier

**Description:** Piattaforma Android 10+ (CallScreeningService, gestione ruolo, permessi runtime) e rete/carrier voce-SMS. Esegue screening, disconnessione e recapito SMS.

**Access Scope:** API di sistema invocate dal modulo nativo; nessun dato utente lascia il dispositivo verso backend (non esiste backend).

**Key interactions:**
- Notifica la chiamata in ingresso al CallScreeningService prima della suoneria.
- Esegue il rifiuto/silenziamento su comando dell'app entro il timeout di piattaforma.
- Fornisce accesso in lettura a stato rubrica e recapita gli SMS in ingresso/in uscita.

### 3.4 Quality & Regulatory Affairs

**Description:** Funzione qualità/owner di prodotto che verifica completezza documentale, gestione PII e conformità alle policy Play prima del rilascio.

**Key interactions:** Review del Service Overview e dei requisiti, verifica informativa privacy e giustificazione permessi SMS, gate di pubblicazione Play.

## 4. Scope Definition

### 4.1 In Scope

| Capability | Description |
|---|---|
| Intercettazione pre-suoneria (RF-1) | CallScreeningService nativo Kotlin intercetta ogni chiamata in ingresso prima del suono della suoneria. |
| Rifiuto automatico sconosciuti (RF-2) | Se il numero è visibile e non è in rubrica né in whitelist, la chiamata è rifiutata/silenziata automaticamente. |
| Registrazione tentativo (RF-3) | Ogni chiamata rifiutata è registrata in lista in-app con numero, data/ora, esito, stato SMS inviato, note. Persistenza locale al riavvio. |
| SMS automatico configurabile (RF-4, RF-9) | All'evento rifiutato, invio automatico di SMS al numero con testo modificabile in-app; default: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione." |
| Whitelist passante (RF-5) | I numeri in whitelist non vengono mai rifiutati e squillano normalmente. |
| Blacklist sempre rifiutata (RF-6) | I numeri in blacklist sono sempre rifiutati; invio SMS secondo configurazione utente. |
| Vista SMS con CTA rapide (RF-7) | All'apertura dell'app, gli SMS in ingresso sono mostrati in vista dedicata con CTA "Accetta (whitelist)" e "Rifiuta (blacklist)". |
| Gestione liste e profili (RF-8) | Whitelist/blacklist gestibili: aggiunta, rimozione, modifica profilo numero (nome, note, categoria, data di aggiunta). |
| Propagazione immediata decisioni (RF-10) | Le decisioni whitelist/blacklist aggiornano immediatamente il comportamento di screening. |

### 4.2 Out of Scope

| Exclusion | Reason |
|---|---|
| iOS e altre piattaforme | iOS non consente intercettazione a runtime né invio/lettura automatica SMS; solo blocchi statici via Call Directory — fuori perimetro dichiarato. |
| Cloud/backend e sincronizzazione multi-dispositivo | Prodotto volutamente offline-first e on-device per privacy; nessun server da mantenere in questa fase. |
| Chiamate in uscita | Il filtro opera solo sulle chiamate in ingresso; nessun requisito sulle uscenti. |
| Scoring anti-spam / directory globali | Nessuna inferenza automatica né lookup esterni; la classificazione è solo manuale dell'utente. |
| Autenticazione/identità centralizzata | App single-user sul dispositivo; nessuna identità remota da gestire. |

## 5. Design Guidelines

| # | Principle | Rationale |
|---|---|---|
| P-01 | Screening nel nativo Kotlin, UI in Flutter | Solo CallScreeningService con ROLE_CALL_SCREENING su Android 10+ può intercettare/rifiutare pre-suoneria; Flutter non ha accesso diretto — dialogo via platform channel. |
| P-02 | On-device first, nessun dato fuori dal telefono | Numeri e SMS sono PII: cronologia e liste in storage locale; nessun backend, nessuna analytics con PII — minimizza superficie GDPR e policy Play. |
| P-03 | Risposta di screening entro il timeout di piattaforma | La decisione rifiuta/lascia-passare deve chiudersi entro il timeout di sistema per non ritardare la suoneria; fail-open su errore/timeout. |
| P-04 | Ordine di valutazione fisso: blacklist → rubrica/whitelist → sconosciuto | Garantisce RF-5/RF-6 senza ambiguità e rende il comportamento testabile e spiegabile all'utente. |
| P-05 | Testo SMS con default precompilato e modificabile | Default normativo già definito nel brief; l'utente può personalizzarlo senza svuotarlo (validazione non-vuoto). |
| P-06 | Mai PII nei log | Log solo con esiti/contatori anonimi per diagnosi senza esporre numeri o contenuti SMS. |

## 6. Assumptions

| # | Assumption | Impact if False |
|---|---|---|
| A-01 | L'utente assegna all'app il ruolo di call screening e concede permessi telefono, rubrica, SMS | Senza ruolo/permessi lo screening e l'SMS non funzionano; serve onboarding guidato con stati degradati espliciti. |
| A-02 | Il numero chiamante è disponibile come "visibile" nella maggior parte dei casi rilevanti | Numeri nascosti/sconosciuti non sono indirizzabili via SMS e non possono essere richiamati: serve policy dedicata (lascia passare + nessuna registrazione SMS). |
| A-03 | Un SMS di risposta per tentativi è un costo accettabile per l'utente (piano tariffario) | Se il costo è un problema, serve opzione "non inviare SMS" per blacklist e contatore costi — già prevista configurabilità RF-6. |
| A-04 | La lettura della rubrica per il confronto è affidabile e performante sul dispositivo | Se lenta, serve cache locale dei numeri normalizzati con refresh esplicito. |
| A-05 | Un singolo dispositivo Android 10+ copre il target iniziale | Se serve supporto < API 29, va ridisegnato lo screening (fuori perimetro attuale). |

## 7. Constraints

| # | Constraint | Source |
|---|---|---|
| C-01 | Android-only, Android 10+ (API 29+), modulo nativo Kotlin con CallScreeningService e ROLE_CALL_SCREENING | Brief di progetto — vincolo di piattaforma IMPORTANTE |
| C-02 | UI in Flutter, dialogo col nativo solo via platform channel | Brief di progetto — architettura imposta |
| C-03 | SEND_SMS e RECEIVE_SMS sono permessi restricted su Google Play: richiesta giustificazione di core functionality | Policy Google Play — rischio pubblicazione |
| C-04 | Nessun dato personale fuori dal dispositivo; persistenza locale che sopravvive al riavvio | Brief NFR privacy + persistenza |
| C-05 | Decisione di screening entro il timeout di piattaforma, senza ritardare la suoneria oltre i limiti di sistema | Brief NFR affidabilità |
| C-06 | Testo SMS di default immutato alla prima installazione: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione." | Brief di progetto — Testo SMS di default |

## 8. Open Decisions & Residual Questions

### 8.1 Decisions Made

| ID | Question | Decision | Rationale |
|---|---|---|---|
| D-01 | Dove avviene lo screening? | Modulo nativo Kotlin (CallScreeningService), UI Flutter via platform channel | Solo il nativo può intercettare pre-suoneria su Android; iOS escluso per limiti di piattaforma. |
| D-02 | Backend sì/no? | No backend in questa fase, solo persistenza locale | Minimizza privacy/scope; sincronizzazione esplicitamente fuori perimetro. |
| D-03 | Comportamento per numeri nascosti? | Non rifiutati via SMS (non indirizzabili); passano o sono silenziati secondo impostazione, senza invio SMS | Non esiste destinatario SMS; evita errori di invio. |
| D-04 | SMS per numeri in blacklist? | Rifiuto sempre; invio SMS configurabile (default: non inviare) | Evita di sollecitare spammer noti e di generare costi inutili. |

### 8.2 Residual Questions & Open Decisions

| ID | Question | Owner | Target Date | Status |
|---|---|---|---|---|
| Q-01 | Strategia di pubblicazione Play con SEND_SMS/RECEIVE_SMS restricted: dichiarazione core-functionality accettata o serve canale alternativo (sideload/OEM)? | Aldo (PM) | 2026-10-20 | Open |
| Q-02 | Intercettazione SMS "all'apertura dell'app": basta lettura SMS inbox all'avvio o serve receiver sempre attivo? Impatto su batteria/policy? | Tech lead | 2026-10-18 | Open |
| Q-03 | Normalizzazione numeri per confronto rubrica/whitelist (prefissi +39, spazi, formati internazionali)? | Tech lead | 2026-10-18 | Open |
| Q-04 | Limite conservazione cronologia e cancellazione PII: retention di default e "cancella tutto"? | Aldo (PM) | 2026-10-20 | Open |

### 8.3 Future Considerations

> **Sincronizzazione multi-dispositivo e backup cloud — Out of Scope per questa fase.**
> Richiesta naturale dopo l'adozione single-device, ma introduce trattamento PII fuori dal telefono (cifratura E2E, gestione chiavi, informativa aggiornata, DPA). Prerequisiti: valutazione privacy, scelta architettura backup, consenso esplicito.

> **Rilevamento spam assistito / directory condivise — Out of Scope per questa fase.**
> Qualsiasi scoring o lookup esterno cambia il principio P-02/P-04 e richiede revisione privacy e policy Play prima del disegno. Tag: Future-Phase, Privacy.

---

*End of Document — CG-OVW-001 v0.1.0*
*Next in package: CG-UC-001 — Use Cases*
