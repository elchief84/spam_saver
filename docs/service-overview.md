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
| Approver | — | — | — |

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

Call Guard è un'app Android che protegge l'utente dalle chiamate da numeri sconosciuti con un filtro automatico locale: intercetta ogni chiamata in ingresso prima che squilli e, se il numero è visibile ma non è in rubrica né in whitelist, rifiuta automaticamente la chiamata, registra il tentativo in una cronologia consultabile in-app e invia al chiamante un SMS automatico configurabile che chiede di identificarsi via SMS. All'apertura dell'app, gli SMS di risposta ricevuti vengono intercettati e mostrati in una vista dedicata con azioni rapide ACCETTA (whitelist) / RIFIUTA (blacklist), che aggiornano immediatamente il comportamento futuro del filtro.

Il prodotto non ha backend né cloud: è un'app single-user, offline-first, composta da un modulo nativo Kotlin (CallScreeningService, ruolo ROLE_CALL_SCREENING, Android 10+) per intercettazione/rifiuto e da UI Flutter che dialoga con il nativo via platform channel per cronologia, liste e configurazione SMS.

Utenti e valore:

- Utente proprietario del dispositivo, infastidito da chiamate indesiderate o ambigue da numeri non in rubrica. Beneficio misurabile: zero squilli da numeri sconosciuti non autorizzati, traccia completa dei tentativi rifiutati, classificazione di un numero in meno di due tocchi dalla vista SMS.
- Chiamante legittimo ma sconosciuto (es. corriere, medico, nuovo contatto). Beneficio: riceve subito un SMS che spiega il rifiuto e come farsi identificare, senza dover richiamare a vuoto.

Successo minimo: filtro attivo con ruolo di call screening assegnato, rifiuto silenzioso dei numeri sconosciuti visibili, cronologia persistente al riavvio, SMS automatico inviato con testo configurabile.

---

## 2. Clinical Significance & Regulatory Qualification

### 2.1 Nature of Data / Content / Function Managed

Call Guard non gestisce dati clinici e non è un dispositivo medico. Non genera, trasforma né inferisce informazioni cliniche.

Dati gestiti, tutti personali e solo on-device:

- Numeri di telefono chiamanti (PII), data/ora chiamata, esito (rifiutata/passante), stato invio SMS, note utente.
- Contenuto degli SMS: testo automatico configurato dall'utente (default sotto) e testi di risposta ricevuti dai chiamanti.
- Liste whitelist/blacklist con profilo del numero: nome, note, categoria, data di aggiunta.
- Rubrica del dispositivo, letta solo per decidere se un numero è noto (nessuna copia/duplicazione oltre il necessario al confronto).

Esempio rappresentativo: `+39 333 1234567, 2026-10-10 09:41, rifiutata, SMS inviato, nota: "ha risposto: sono il corriere"`.

Testo SMS di default (precompilato e modificabile in-app):

> "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."

### 2.2 User Safety Obligation

Pur non avendo obblighi di patient safety, Call Guard ha un obbligo di non-nocumento verso l'utente: un errore del filtro può far perdere chiamate importanti (es. emergenze, medico, lavoro) o generare costi SMS indesiderati.

Modi di guasto e controlli non negoziabili:

| Control | Implementation |
|---|---|
| Mai bloccare numeri noti | Whitelist e contatti rubrica passano sempre; il check whitelist/rubrica precede qualsiasi rifiuto (RF-5). |
| Numeri anonimi/non visibili non gestiti come sconosciuti noti | Il rifiuto automatico scatta solo con numero visibile e non in rubrica/whitelist (RF-2); i numeri nascosti seguono il comportamento di default del sistema. |
| Decisione utente effettiva subito | Whitelist/blacklist aggiornano immediatamente il comportamento del filtro (RF-10); nessuna cache che ritarda l'effetto. |
| Nessuna perdita di traccia | Ogni chiamata rifiutata è registrata con numero, data/ora, esito, stato SMS, note (RF-3) e la persistenza locale sopravvive al riavvio. |
| Nessun PII nei log | Log tecnici senza numeri di telefono né contenuto SMS; numeri solo nello storage applicativo cifrato dal sistema. |
| Risposta entro timeout di piattaforma | Il CallScreeningService risponde in modo sincrono e leggero, senza I/O bloccante nel percorso di screening. |

> **Mandatory principle:** Call Guard non lascia mai il dispositivo nessun numero, SMS o nota. Qualsiasi futura richiesta di cloud, analytics o sincronizzazione multi-dispositivo richiede una revisione privacy e un gate di scope prima del disegno.

### 2.3 Regulatory Qualification

Call Guard non è MDSW, non rientra in EU MDR né FDA 21 CFR 820/QMSR, e la classificazione IEC 62304 non è applicabile (nessuna funzione di dispositivo medico; giustificazione: guasto = chiamata persa o SMS indesiderato, nessun danno clinico diretto).

Regolamentazione applicabile:

- Google Play Policy su permessi sensibili: `SEND_SMS` e `RECEIVE_SMS` sono permessi restricted che richiedono dichiarazione d'uso e giustificazione in fase di pubblicazione; rischio concreto di rifiuto in review. Il ruolo `ROLE_CALL_SCREENING` e i permessi telefono richiedono consenso esplicito assegnato dall'utente.
- Protezione dati (GDPR, ove applicabile): numeri di telefono e contenuti SMS sono dati personali; base giuridica = uso locale su incarico dell'interessato-proprietario; nessun trasferimento, nessuna conservazione oltre il dispositivo, cancellazione tramite rimozione in-app.

---

## 3. Actors & Stakeholders

### 3.1 Utente proprietario del dispositivo

**Description:** Possessore del telefono Android che installa e configura Call Guard, assegna il ruolo di call screening e gestisce cronologia, liste e testo SMS.

**Access Scope:** Pieno controllo locale: lettura cronologia e SMS intercettati, scrittura whitelist/blacklist/profili, modifica testo SMS.

**Key interactions:**
- Assegna all'app il ruolo di call screening e concede permessi telefono/SMS/contatti.
- Consulta la lista chiamate rifiutate con numero, data/ora, esito, stato SMS, note.
- Classifica i numeri dalla vista SMS con ACCETTA (whitelist) / RIFIUTA (blacklist).
- Aggiunge, rimuove e modifica profili in whitelist/blacklist (nome, note, categoria, data aggiunta).
- Modifica il testo dell'SMS automatico.

---

### 3.2 Chiamante sconosciuto

**Description:** Persona che chiama da numero visibile non presente in rubrica né in whitelist. Non usa direttamente l'app.

**Access Scope:** Nessuno; interagisce solo via rete telefonica/SMS.

**Key interactions:**
- Viene rifiutato automaticamente se visibile e non noto (RF-2, RF-6).
- Riceve l'SMS automatico di richiesta identificazione (RF-4, salvo configurazione blacklist senza SMS).
- Può rispondere via SMS, messaggio poi mostrato all'utente per la classificazione (RF-7).

---

### 3.3 Sistema operativo Android e carrier

**Description:** Piattaforma che fornisce call screening, telefonia e SMS; rete dell'operatore che recapita chiamate e SMS.

**Access Scope:** Permessi concessi dall'utente: screening chiamate, lettura contatti, invio/ricezione SMS, lettura stato telefono.

**Key interactions:**
- Notifica al `CallScreeningService` ogni chiamata in ingresso prima della suoneria.
- Esegue disconnessione/silenziamento su comando dell'app entro il timeout di piattaforma.
- Recapita l'SMS automatico e gli SMS in ingresso; comportamento di rifiuto può variare per carrier/rete.

---

### 3.4 Quality & Review interno

**Description:** PM e revisori interni che approvano documenti, verificano acceptance criteria e presidiano rischi Play Policy e privacy.

**Key interactions:** Revisione e approvazione del Service Overview e dei documenti a valle, verifica tracciabilità RF-1…RF-10, monitoraggio rischi di pubblicazione.

---

## 4. Scope Definition

### 4.1 In Scope

| Capability | Description |
|---|---|
| Intercettazione pre-suoneria (RF-1) | Ogni chiamata in ingresso è intercettata dal modulo nativo prima del suono della suoneria. |
| Rifiuto automatico sconosciuti (RF-2) | Numero visibile non in rubrica né whitelist → chiamata rifiutata automaticamente (disconnessa/silenziata). |
| Cronologia tentativi (RF-3) | Lista in-app di ogni chiamata rifiutata con numero, data/ora, esito, stato SMS inviato, note; persistente al riavvio. |
| SMS automatico configurabile (RF-4, RF-9) | Invio automatico di SMS al numero rifiutato con testo modificabile in-app e default precompilato (§2.1). |
| Whitelist passante (RF-5) | Numeri in whitelist non vengono mai rifiutati. |
| Blacklist sempre rifiutata (RF-6) | Numeri in blacklist sempre rifiutati, con invio SMS secondo configurazione (incluso mai). |
| Vista SMS con CTA rapide (RF-7) | All'apertura dell'app, SMS in ingresso intercettati e mostrati con CTA Accetta (whitelist) / Rifiuta (blacklist). |
| Gestione liste e profili (RF-8) | Whitelist/blacklist gestibili: aggiunta, rimozione, modifica profilo (nome, note, categoria, data aggiunta). |
| Effetto immediato decisioni (RF-10) | Whitelist/blacklist aggiornano subito il comportamento di rifiuto. |
| Persistenza locale e privacy on-device | Cronologia e liste in storage locale; nessun dato lascia il dispositivo; nessun PII nei log. |

### 4.2 Out of Scope

| Exclusion | Reason |
|---|---|
| iOS e altre piattaforme | iOS non consente intercettazione a runtime né invio/lettura automatica SMS (solo blocchi statici via Call Directory); perimetro Android-only. |
| Cloud/backend e sincronizzazione multi-dispositivo | Scelta di prodotto: solo locale per privacy e semplicità; ogni cloud richiede Change Request e revisione privacy. |
| Chiamate in uscita | Non intercettate né registrate; fuori dal problema dichiarato. |
| Blocco statico stile iOS / filtri carrier | Responsabilità di OS/operatore, non implementati nell'app. |
| Rilevamento spam basato su database esterni o ML | Nessuna inferenza né fonte esterna; solo rubrica + liste utente. |
| Backup/restore oltre la persistenza locale | Differito; non richiesto dai requisiti funzionali. |

---

## 5. Design Guidelines

| # | Principle | Rationale |
|---|---|---|
| P-01 | Nativo Kotlin per lo screening, Flutter solo per UI | Solo `CallScreeningService` può intercettare/rifiutare pre-suoneria su Android 10+; la UI non deve mai stare nel percorso critico della chiamata. Dialogo via platform channel. |
| P-02 | Risposta di screening sincrona e leggera | L'intercettazione non deve ritardare la suoneria oltre i limiti di sistema; niente I/O bloccante o rete nel callback di screening. |
| P-03 | Dati solo on-device, nessun PII nei log | Numeri e SMS sono PII: restano nello storage locale, mai nei log né in rete; base per conformità Play Policy e GDPR. |
| P-04 | Ordine decisionale fisso: blacklist → whitelist/rubrica → sconosciuto | Previene errori di classificazione: blacklist sempre rifiutata, noti sempre passanti, solo il residuo visibile va al rifiuto + SMS. |
| P-05 | Configurabilità utente con default sicuro | Testo SMS precompilato col default approvato ma sempre modificabile; blacklist con opzione invio SMS sì/no. |
| P-06 | Effetto immediato e tracciabilità | Ogni decisione whitelist/blacklist ha effetto subito e ogni rifiuto lascia una riga di cronologia completa (numero, data/ora, esito, stato SMS, note). |
| P-07 | Tracer-bullet: task piccoli con stima, acceptance e dipendenze | Standard di pianificazione del team: niente scadenze senza stima, niente allargamento scope senza gate. |

---

## 6. Assumptions

| # | Assumption | Impact if False |
|---|---|---|
| A-01 | L'utente assegna all'app il ruolo di call screening e concede permessi telefono, contatti e SMS | Senza ruolo/permessi il filtro non opera; serve onboarding che spiega e reverifica lo stato a ogni avvio. |
| A-02 | Target Android 10+ con `CallScreeningService` disponibile e carrier che supporta rifiuto programmatico | Su versioni inferiori o carrier anomali il rifiuto può fallire; serve fallback (silenziamento) e messaggio dedicato. |
| A-03 | Numero chiamante visibile nella maggior parte dei casi indesiderati | Numeri anonimi seguono il comportamento di sistema e non generano SMS; se prevalgono, lo scope va rivisto con Change Request. |
| A-04 | Invio SMS dal dispositivo sempre disponibile e con costo accettato dall'utente | Se l'invio fallisce o il costo frena l'adozione, serve configurazione per-numero/lista e retry visibile in cronologia. |
| A-05 | La rubrica è la fonte di verità dei numeri noti, integrata dalla whitelist | Se l'utente non mantiene la rubrica, la whitelist diventa il meccanismo primario e la UX deve renderlo evidente. |

---

## 7. Constraints

| # | Constraint | Source |
|---|---|---|
| C-01 | Android-only, modulo nativo Kotlin con `ROLE_CALL_SCREENING`, min Android 10+; UI Flutter via platform channel | Brief di progetto — vincolo di piattaforma |
| C-02 | `SEND_SMS` / `RECEIVE_SMS` sono permessi restricted su Google Play e richiedono giustificazione; rischio di rifiuto in pubblicazione | Google Play Policy — vincolo pubblicazione |
| C-03 | Nessun dato (numeri, SMS, note) lascia il dispositivo; nessun PII nei log | Brief NFR privacy + GDPR |
| C-04 | Risposta di screening entro il timeout di piattaforma, senza ritardo percepibile della suoneria per i numeri noti | Brief NFR affidabilità + limiti Android |
| C-05 | Persistenza locale di cronologia e liste oltre il riavvio | Brief NFR persistenza |
| C-06 | Testo SMS default fisso come in §2.1, sempre modificabile in-app | Brief — Testo SMS di default + RF-9 |

---

## 8. Open Decisions & Residual Questions

### 8.1 Decisions Made

| ID | Question | Decision | Rationale |
|---|---|---|---|
| D-01 | Dove avviene il filtro? | Modulo nativo Kotlin, Flutter solo UI via platform channel | Solo il nativo può fare screening pre-suoneria su Android. |
| D-02 | iOS va supportato? | No, fuori perimetro | iOS non consente intercettazione runtime né SMS automatici. |
| D-03 | Serve un backend? | No, solo storage locale | Privacy on-device e scope approvato; cloud solo via Change Request. |
| D-04 | SMS ai numeri in blacklist? | Sì, ma configurabile (incluso nessun invio) | Evita di sollecitare molestatori noti; decisione utente per lista. |

### 8.2 Residual Questions & Open Decisions

| ID | Question | Owner | Target Date | Status |
|---|---|---|---|---|
| Q-01 | Fallback esatto quando il rifiuto programmatico fallisce (disconnessione vs silenziamento) per carrier/OEM? | PM + Dev Android | Da fissare prima SRS | Open |
| Q-02 | Comportamento con numeri anonimi/nascosti: solo passanti o opzione utente di silenziamento? | PM | Da fissare prima SRS | Open |
| Q-03 | Strategia di giustificazione Play per SEND_SMS/RECEIVE_SMS e piano B se rifiutata (es. intent SMS senza invio diretto)? | PM | Da fissare prima pubblicazione | Open |
| Q-04 | Limiti di conservazione cronologia/SMS (cap righe, retention) per restare leggibili e leggeri? | PM | Da fissare prima SRS | Open |
| Q-05 | Formato categoria del profilo numero (lista chiusa vs libera) e categorie iniziali? | PM | Da fissare prima UI | Open |

### 8.3 Future Considerations

> **Sincronizzazione multi-dispositivo e backup cloud — Out of Scope for this phase.**
> Richiesta plausibile ma esclusa: introdurrebbe trasferimento PII fuori dal dispositivo. Prerequisiti prima di qualsiasi disegno: Change Request sullo scope, base giuridica e consenso GDPR, cifratura end-to-end e revisione Play Policy. Tag: Future-Phase, GDPR.

> **Filtri anti-spam con database esterni o punteggio ML — Out of Scope for this phase.**
> Esclusi per mantenere il filtro deterministico (rubrica + liste). Prerequisiti: valutazione accuratezza, spiegabilità all'utente e impatto privacy di ogni fonte esterna. Tag: Future-Phase, GDPR.

---

*End of Document — CG-OVW-001 v0.1.0*
*Next in package: CG-UC-001 — Use Cases*
