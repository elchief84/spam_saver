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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft per brief Call Guard (RF-1…RF-10) |

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

Call Guard è un'app Android che protegge l'utente dalle chiamate da numeri sconosciuti: intercetta ogni chiamata in ingresso prima che squilli e, se il numero è visibile ma non è in rubrica né in whitelist, la rifiuta automaticamente, la registra in una lista in-app consultabile e invia al chiamante un SMS automatico configurabile. All'apertura dell'app, le risposte SMS ricevute vengono mostrate con azioni rapide per classificare il numero in whitelist o blacklist.

Utente concreto: il proprietario di uno smartphone Android che riceve chiamate indesiderate o ambigue da numeri non in rubrica e vuole non essere disturbato, senza perdere la possibilità di ricontattare o identificare il chiamante.

Beneficio misurabile: zero squilli da numeri sconosciuti non autorizzati; ogni tentativo rifiutato lascia una traccia (numero, data/ora, esito, stato SMS, note); ogni risposta del chiamante è classificabile in massimo 2 tap (ACCETTA / RIFIUTA); il testo SMS è personalizzabile con un default già pronto.

Testo SMS di default (precompilato e modificabile in-app):

> "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."

Non è un dispositivo medico, non ha backend/cloud, non gestisce dati sanitari. È un prodotto consumer single-device, offline-first, con persistenza locale.

---

## 2. Clinical Significance & Regulatory Qualification

### 2.1 Nature of Data / Function Managed

Call Guard non gestisce dati clinici, non genera, non trasforma e non inferisce alcuna informazione sanitaria. I dati trattati sono esclusivamente:

- numeri di telefono (PII secondo GDPR), visibili solo se il chiamante non li ha oscurati;
- metadati di chiamata: data/ora, esito (rifiutata/passata), stato invio SMS;
- contenuti SMS inviati (template configurabile) e ricevuti (risposte di identificazione);
- liste utente: whitelist, blacklist, rubrica (lettura), profilo numero (nome, note, categoria, data di aggiunta).

Esempi rappresentativi: "+39 333 000 0000 — 2026-10-10 09:41 — rifiutata — SMS inviato"; "risposta SMS: 'Sono Rossi, idraulico'".

### 2.2 User Safety / Reliability Obligation

Pur non avendo obblighi di patient safety, Call Guard ha un obbligo di affidabilità verso l'utente: un errore può far perdere chiamate legittime (falso positivo) o far passare spam (falso negativo), o inviare SMS indesiderati con costi e impatti privacy.

Controlli tecnici non negoziabili:

| Control | Implementation |
|---|---|
| Mai bloccare senza regola chiara | Rifiuto solo se numero visibile E non in rubrica E non in whitelist; numeri in whitelist passano sempre (RF-5); numeri anonimi/oscurati non coperti da rifiuto automatico |
| Decisioni utente applicate subito | Whitelist/blacklist aggiornano immediatamente il comportamento di screening (RF-10); nessuna cache stale tra UI e modulo nativo |
| Screening entro timeout di piattaforma | Il CallScreeningService risponde entro il timeout Android senza lavoro pesante nel callback; persistenza e invio SMS avvengono in modo asincrono |
| Nessun PII nei log | I log contengono solo hash/flag e codici esito, mai numeri in chiaro né contenuti SMS |
| Nessuna esfiltrazione | Nessuna rete/backend: tutti i dati restano sul dispositivo |

> **Mandatory principle:** Call Guard non inferisce identità né intenzioni del chiamante. La classificazione è solo esplicita dall'utente (whitelist/blacklist). Qualsiasi evoluzione verso scoring automatico, reputazione o condivisione cloud dei numeri richiede una revisione di scopo, privacy e policy Play prima del design.

### 2.3 Regulatory Qualification

Call Guard non è un MDSW/SaMD e non ricade sotto EU MDR, FDA 21 CFR 820/QMSR, IEC 62304 o ISO 14971/ISO 13485. Nessuna classe di sicurezza IEC 62304 applicabile.

Il quadro regolatorio applicabile è:

- GDPR / normativa privacy nazionale: i numeri di telefono sono dati personali; base giuridica e consenso, minimizzazione, conservazione locale, diritti dell'interessato per i dati del chiamante nei limiti del legittimo interesse e dell'uso strettamente personale/domestico;
- Google Play Policy (permessi sensibili telefono/SMS, ruolo call screening): i permessi SEND_SMS e RECEIVE_SMS sono "restricted" e richiedono dichiarazione d'uso e approvazione; rischio di rifiuto in fase di pubblicazione;
- normativa telecomunicazioni/antispam nazionale per l'invio automatico di SMS.

---

## 3. Actors & Stakeholders

### 3.1 Utente proprietario del dispositivo

**Description:** Proprietario dello smartphone Android. Configura il ruolo di call screening, il testo SMS, consulta la cronologia, classifica i numeri e gestisce whitelist/blacklist.

**Access Scope:** pieno controllo locale su cronologia, liste, template SMS e impostazioni.

**Key interactions:**
- Assegna all'app il ruolo di call screening e concede i permessi telefono/SMS/rubrica.
- Modifica il testo dell'SMS automatico (RF-9).
- Consulta la lista chiamate rifiutate con numero, data/ora, esito, stato SMS, note (RF-3).
- All'apertura dell'app vede gli SMS di risposta con CTA Accetta (whitelist) / Rifiuta (blacklist) (RF-7).
- Aggiunge, rimuove e modifica profili numero in whitelist/blacklist: nome, note, categoria, data di aggiunta (RF-8).

---

### 3.2 Chiamante sconosciuto

**Description:** Persona che chiama da un numero visibile non presente in rubrica né in whitelist. Non usa l'app direttamente; interagisce tramite chiamata rifiutata e SMS automatico.

**Access Scope:** nessuno sull'app; può solo ricevere l'SMS automatico e rispondere via SMS.

**Key interactions:**
- Effettua una chiamata che viene rifiutata automaticamente (RF-2).
- Riceve l'SMS automatico con richiesta di identificazione (RF-4).
- Risponde eventualmente via SMS, fornendo le informazioni per la classificazione.

---

### 3.3 Sistema operativo Android e carrier

**Description:** Android 10+ con ruolo ROLE_CALL_SCREENING, stack telefonico e SMS del carrier. Esegue lo screening pre-squillo e recapita gli SMS.

**Access Scope:** permessi di sistema concessi dall'utente (screening, lettura rubrica, invio/lettura SMS, log chiamate secondo implementazione).

**Key interactions:**
- Notifica la chiamata in ingresso al CallScreeningService prima della suoneria (RF-1).
- Esegue disconnessione/silenziamento su comando dell'app (RF-2, RF-6).
- Recapita l'SMS in uscita e gli SMS in ingresso intercettati dall'app (RF-4, RF-7).

---

### 3.4 Quality / Store & Compliance

**Description:** PM (Aldo) più chi verifica policy Play e privacy prima del rilascio. Nessun team QA/RA medicale.

**Key interactions:** Verifica permessi restricted, informativa privacy, assenza PII nei log, test su Android 10+ e carrier diversi.

---

## 4. Scope Definition

### 4.1 In Scope

| Capability | Description |
|---|---|
| Intercettazione pre-squillo (RF-1) | Ogni chiamata in ingresso è intercettata dal modulo nativo prima del suono della suoneria. |
| Rifiuto automatico sconosciuti (RF-2) | Se il numero è visibile e non è in rubrica né in whitelist, la chiamata è rifiutata automaticamente (disconnessa/silenziata). |
| Whitelist passante (RF-5) | I numeri in whitelist non vengono mai rifiutati: passano normalmente. |
| Blacklist sempre rifiutata (RF-6) | I numeri in blacklist sono sempre rifiutati, con invio SMS secondo configurazione (incluso "senza SMS"). |
| Registro tentativi (RF-3) | Ogni chiamata rifiutata è registrata in lista in-app con numero, data/ora, esito, stato SMS inviato e note. La lista sopravvive al riavvio. |
| SMS automatico configurabile (RF-4, RF-9) | Alla chiamata rifiutata invio automatico di SMS al numero con testo modificabile in-app; default precompilato (vedi §1). |
| Vista risposte SMS con CTA (RF-7) | All'apertura dell'app gli SMS in ingresso sono mostrati in vista dedicata con CTA "Accetta (whitelist)" e "Rifiuta (blacklist)". |
| Gestione liste e profili (RF-8) | Whitelist e blacklist gestibili: aggiunta, rimozione, modifica profilo (nome, note, categoria, data di aggiunta). |
| Effetto immediato decisioni (RF-10) | Le decisioni whitelist/blacklist aggiornano subito il comportamento di screening. |
| Persistenza locale | Cronologia chiamate, liste e template SMS persistenti sul dispositivo, senza backend. |

### 4.2 Out of Scope

| Exclusion | Reason |
|---|---|
| iOS e altre piattaforme | iOS non consente screening a runtime né invio/lettura automatica SMS (solo blocchi statici via Call Directory); perimetro approvato solo Android. |
| Cloud/backend e sincronizzazione multi-dispositivo | Scelta di prodotto: solo locale per privacy e semplicità; eventuale sync è fase futura con Change Request. |
| Chiamate in uscita | Non richieste dal brief; nessuno screening o logging in uscita. |
| Numeri anonimi/oscurati | Il brief copre solo numeri visibili; il trattamento degli anonimi è decisione aperta (vedi Q-02). |
| Scoring/reputazione automatica, anti-spam cloud, statistiche aggregate | Inferenza e condivisione dati fuori scopo; richiederebbero nuova valutazione privacy e policy Play. |
| Backup/restore cross-device | Rinviato a fase futura (vedi §8.3). |

---

## 5. Design Guidelines

| # | Principle | Rationale |
|---|---|---|
| P-01 | Nativo Kotlin per lo screening, Flutter solo per UI | Solo CallScreeningService con ROLE_CALL_SCREENING su Android 10+ può intercettare pre-squillo; Flutter dialoga via platform channel e non sta nel percorso critico temporale. |
| P-02 | Screening snello e asincrono | La risposta di screening deve stare entro il timeout di piattaforma: nessuna I/O pesante nel callback; log, DB e invio SMS in async. |
| P-03 | Single source of truth locale | Rubrica (read-only) + whitelist + blacklist + cronologia in storage locale; le decisioni UI propagano subito al modulo nativo senza cache stale. |
| P-04 | PII solo on-device, mai nei log | Numeri e contenuti SMS non lasciano il dispositivo e non compaiono nei log (solo hash/flag ed esiti); minimizzazione GDPR. |
| P-05 | Default utile, tutto configurabile | Template SMS precompilato con il default approvato; utente libero di modificarlo; blacklist configurabile con/senza SMS. |
| P-06 | Classificazione in 2 tap | La vista SMS offre solo Accetta/Rifiuta con conferma immediata; liste leggibili, azioni rapide, niente flussi profondi. |
| P-07 | Permessi minimi e dichiarati | Solo permessi telefono/SMS/rubrica/screening necessari a RF-1…RF-9, con informativa e giustificazione Play pronte; nessun permesso extra. |

---

## 6. Assumptions

| # | Assumption | Impact if False |
|---|---|---|
| A-01 | L'utente assegna all'app il ruolo di call screening e concede i permessi telefono/SMS/rubrica. | Senza ruolo/permessi lo screening e l'SMS non funzionano: serve onboarding guidato con fallback "solo registro manuale". |
| A-02 | Il dispositivo è Android 10+ con CallScreeningService supportato dal vendor/carrier. | Su versioni inferiori o ROM che limitano lo screening serve gate di compatibilità e messaggio esplicito di non supporto. |
| A-03 | Il numero del chiamante è disponibile e visibile nella maggior parte dei casi d'uso target. | Con alta quota di anonimi il valore cala: rivalutare Q-02 (gestione anonimi) e la comunicazione di prodotto. |
| A-04 | L'invio SMS è disponibile (credito/piano, segnale) al momento del rifiuto. | Serve stato "SMS non inviato / da ritentare" nel registro (RF-3) e policy di retry senza spam. |
| A-05 | L'utente apre l'app con regolarità per vedere le risposte SMS (RF-7 è on-open, non push). | Se l'uso è rado, le risposte restano in attesa: valutare notifica locale (Change Request, non in scope). |

---

## 7. Constraints

| # | Constraint | Source |
|---|---|---|
| C-01 | Android-only, modulo nativo Kotlin con CallScreeningService, ROLE_CALL_SCREENING, Android 10+; UI Flutter via platform channel. | Brief progetto — vincolo di piattaforma. |
| C-02 | SEND_SMS e RECEIVE_SMS sono permessi restricted su Google Play: servono dichiarazione d'uso e approvazione; la pubblicazione può essere rifiutata. | Google Play Policy — vincolo store/compliance. |
| C-03 | Nessun dato lascia il dispositivo; nessun PII nei log; persistenza locale che sopravvive al riavvio. | Brief (privacy, persistenza) + GDPR. |
| C-04 | La risposta di screening non deve ritardare la suoneria oltre il timeout di piattaforma. | Brief (affidabilità) + limiti Android. |
| C-05 | Template SMS default invariato salvo modifica utente; default: "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione." | Brief — Testo SMS di default. |
| C-06 | Niente iOS, niente backend/cloud/sync, niente chiamate in uscita. | Brief — Fuori perimetro. |

---

## 8. Open Decisions & Residual Questions

### 8.1 Decisions Made

| ID | Question | Decision | Rationale |
|---|---|---|---|
| D-01 | Dove avviene lo screening? | Modulo nativo Kotlin (CallScreeningService), Flutter solo UI via platform channel. | Solo il nativo può agire pre-squillo su Android 10+ con ruolo dedicato. |
| D-02 | Cosa succede ai numeri in whitelist/blacklist? | Whitelist passa sempre; blacklist sempre rifiutata con SMS secondo configurazione. | Comportamento deterministico e subito aggiornato (RF-5, RF-6, RF-10). |
| D-03 | Quando si mostrano gli SMS di risposta? | All'apertura dell'app in vista dedicata con CTA Accetta/Rifiuta. | Come da brief RF-7; niente push/background oltre l'on-open in questa fase. |
| D-04 | Dove stanno i dati? | Solo storage locale on-device, nessuna rete. | Privacy (GDPR), semplicità, brief. |

### 8.2 Residual Questions & Open Decisions

| ID | Question | Owner | Target Date | Status |
|---|---|---|---|---|
| Q-01 | Configurazione blacklist: SMS sempre inviato, mai inviato, o per-numero? Il brief dice "secondo configurazione" (RF-6). Quale default? | Aldo (PM) | 2026-10-17 | Open |
| Q-02 | Come trattare i numeri anonimi/oscurati (non "visibili")? Rifiuto, passaggio, o opzione utente? | Aldo (PM) | 2026-10-17 | Open |
| Q-03 | Serve retry visibile per SMS non inviati (assenza segnale/credito) con stato in lista? Quale policy (1 retry, coda, notifica)? | Aldo (PM) | 2026-10-17 | Open |
| Q-04 | Giustificazione Play per SEND_SMS/RECEIVE_SMS: l'uso "risposta automatica a chiamata rifiutata" sarà accettato come core purpose? Piano B (distribuzione fuori Play / funzione ridotta) se rifiutato? | Aldo (PM) | 2026-10-24 | Open |
| Q-05 | Lettura rubrica: quale source e matching (normalizzazione +39/spazi) e quale comportamento se contatto aggiunto dopo il rifiuto? | Aldo (PM) | 2026-10-17 | Open |

### 8.3 Future Considerations

> **Notifiche push/locali per risposte SMS — Out of Scope per questa fase.**
> Oggi le risposte si vedono aprendo l'app (RF-7). Una notifica migliorerebbe la tempestività ma introduce permessi/background epolicy Play aggiuntivi. Prerequisiti: decisione PM, valutazione batteria/privacy, Change Request.

> **Backup/restore e sync multi-dispositivo — Out of Scope per questa fase.**
> Richiesto solo locale per privacy. Sync implicherebbe backend, cifratura, account e informativa aggiornata. Prerequisiti: nuovo scopo approvato, DPIA, architettura cloud.

> **Gestione numeri anonimi e regole avanzate (orari, categorie) — Out of Scope per questa fase.**
> Deferite in attesa di Q-02 e feedback d'uso. Prerequisiti: decisione PM su default sicuri (mai perdere chiamate legittime), Change Request.

---

*End of Document — CG-OVW-001 v0.1.0*
*Next in package: CG-UC-001 — Use Cases*
