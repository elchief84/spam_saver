# Call Guard — Risk Analysis (ISO 14971)

**Document ID:** CG-RSK-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Standard:** ISO 14971:2019 (applicata in modo proporzionato ad app non medicale)
**Last Updated:** 2026-10-10
**Trace Parents:** RF-1 · RF-2 · RF-3 · RF-4 · RF-5 · RF-6 · RF-7 · RF-8 · RF-9 · RF-10

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Aldo (PM) | 2026-10-10 | Aldo |
| Reviewer | Team Call Guard (da assegnare) | — | — |
| Approver (QA/RA) | Da assegnare | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-10 | Aldo (PM) | Prima stesura compilata per Call Guard |

---

## 1. Overview

Call Guard è un'app Android-only (modulo nativo Kotlin con `CallScreeningService`, ruolo `ROLE_CALL_SCREENING`, Android 10+; UI Flutter via platform channel) che rifiuta automaticamente le chiamate da numeri visibili non in rubrica/whitelist, registra il tentativo, invia un SMS automatico configurabile e permette di classificare i numeri in whitelist/blacklist.

Questo documento identifica, valuta e mitiga i rischi di prodotto, tecnici, privacy e compliance. Non è un dispositivo medico: la scala di severità ISO 14971 è mantenuta invariata per coerenza di framework (come richiesto dal template), ma i danni sono interpretati in chiave operativa/legale/economica (chiamate perse, costi SMS, rigetto Play Store, violazione GDPR). Nessun rischio residuo [ALTO] è accettato per il rilascio.

Scope considerato: RF-1…RF-10 del brief, vincoli di piattaforma Android, NFR di affidabilità, privacy (solo on-device) e persistenza locale.

---

## 2. User Needs e contesto d'uso

- Utente proprietario del dispositivo vuole: non essere disturbato da sconosciuti, avere traccia dei tentativi, rispondere con SMS standard senza sforzo, decidere in fretta se fidarsi o bloccare.
- Chiamante sconosciuto legittimo (es. medico, corriere, cliente nuovo) vuole: poter essere richiamato o identificarsi via SMS.
- Contesto critico: chiamate urgenti da numeri nuovi (emergenze, lavoro, sanità); rete/carrier variabile; permessi sensibili; batteria/ottimizzazioni OEM che uccidono il background.

---

## 3. Evaluation Matrix

| **Probability \ Severity** | **Catastrophic (4)** | **Critical (3)** | **Marginal (2)** | **Negligible (1)** |
|---|---|---|---|---|
| **Frequent (6)** | [ALTO] 24 | [ALTO] 18 | [ALTO] 12 | [MEDIO] 6 |
| **Probable (5)** | [ALTO] 20 | [ALTO] 15 | [MEDIO] 10 | [MEDIO] 5 |
| **Occasional (4)** | [ALTO] 16 | [ALTO] 12 | [MEDIO] 8 | [BASSO] 4 |
| **Remote (3)** | [ALTO] 12 | [MEDIO] 9 | [MEDIO] 6 | [BASSO] 3 |
| **Unlikely (2)** | [MEDIO] 8 | [MEDIO] 6 | [BASSO] 4 | [BASSO] 2 |
| **Unbelievable (1)** | [BASSO] 4 | [BASSO] 3 | [BASSO] 2 | [BASSO] 1 |

**Severity Scale:**
| Level | Label | Description |
|---|---|---|
| 4 | Catastrophic | Risk of death or permanent disability |
| 3 | Critical | Risk of serious consequences that may involve hospitalisation or prolonged hospitalisation |
| 2 | Marginal | Risk of mild consequences that may involve minor care (bandages, minor medications, non-invasive diagnostic investigations) |
| 1 | Negligible | Discomfort to the patient or consequences that do not involve the need for medical and/or nursing care |

> Nota di adattamento per Call Guard (app non medicale): la scala sopra è invariata per coerenza di framework. Ai fini pratici di questo documento: Severità 3 = perdita di chiamata urgente con conseguenze gravi per l'utente, breach GDPR, rigetto pubblicazione; Severità 2 = disservizio/fastidio/costo SMS contenuto; Severità 1 = frizione UI minore.

**Probability Scale:**
| Level | Label | Description |
|---|---|---|
| 6 | Frequent | Could happen immediately or within a short period |
| 5 | Probable | Likely to happen; could happen several times in 1 or 2 years |
| 4 | Occasional | Is likely to happen; could happen a few times over a period of 2 to 5 years |
| 3 | Remote | Not expected to happen; could happen in a period between 5 and 30 years |
| 2 | Unlikely | It would arouse amazement that the problem would occur |
| 1 | Unbelievable | It would arouse great amazement that the problem would occur |

**Risk Score = Probability × Severity**

**Acceptability:**
| Colour | Region | Score Range | Action Required |
|---|---|---|---|
| [ALTO] Red | Intolerable | ≥ 12 | Risk reduction measures mandatory before release |
| [MEDIO] Yellow | Conditionally Tolerable | 5 – 11 | ALARP review required; benefit–risk comparison; accepted with justification |
| [BASSO] Green | Broadly Tolerable | ≤ 4 | Residual risk acceptable; no further action required |

> **ALARP note:** Conditionally Tolerable risks that cannot be further reduced must be compared against clinical benefit. If benefit exceeds risk, the risk is accepted as tolerable. If risk exceeds benefit, it escalates to Intolerable.
> Residual risk must NOT remain [ALTO] Intolerable. If it does, additional mitigations are required before this document can be approved.
> Per Call Guard "clinical benefit" si legge come "beneficio utente/business" (meno disturbo, tracciabilità, classificazione rapida).

---

## RSK-101

**Category:** Funzionale — Falso positivo (rifiuto di chiamata legittima urgente)
**Hazard:** Chiamata legittima e potenzialmente urgente da numero nuovo viene rifiutata automaticamente
**Source of Hazard:** Regola RF-2 troppo aggressiva: ogni numero visibile non in rubrica/whitelist è disconnesso/silenziato prima dello squillo, senza eccezioni contestuali
**Hazardous Situation:** Medico, pronto intervento, corriere, cliente o datore di lavoro chiama da numero sconosciuto; l'utente non vede/sente la chiamata e la scopre solo a posteriori dal registro
**Potential Harm:** Perdita di opportunità critica, danno economico o disservizio grave; perdita di fiducia nell'app con disinstallazione

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **5 — Probable** · Score: **15** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- SMS automatico immediato con richiesta di identificazione (RF-4) + stato invio visibile in lista (RF-3), così il chiamante legittimo può farsi riconoscere
- Vista SMS in ingresso con CTA rapide Accetta/Rifiuta all'apertura app (RF-7) e propagazione immediata della decisione (RF-10)
- Whitelist con profilo modificabile (RF-8) e numeri whitelist mai bloccati (RF-5); onboarding che spiega il comportamento e invita a pre-registrare numeri critici
- Registro completo con numero, data/ora, esito, stato SMS, note (RF-3) + eventuale notifica di "chiamata filtrata" per recupero rapido
- Future: eccezioni opzionali per secondi tentativi ravvicinati dello stesso numero e promemoria di richiamata

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **3 — Remote** · Score: **9** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
Il beneficio (eliminazione quasi totale delle chiamate indesiderate con traccia e recupero strutturato) supera il rischio residuo, ridotto a remoto tramite SMS di recupero, registro e whitelist immediata. Rischio accettato in logica ALARP; monitoraggio reclami per "chiamate importanti perse" dopo il lancio.

**Traceability:** RF-2 · RF-3 · RF-4 · RF-5 · RF-7 · RF-8 · RF-10

---

## RSK-102

**Category:** Funzionale — Falso negativo (mancato rifiuto / squillo indesiderato)
**Hazard:** Chiamata spam/sconosciuta squilla nonostante l'app installata
**Source of Hazard:** Ruolo `ROLE_CALL_SCREENING` non assegnato, risposta oltre il timeout di piattaforma, comportamento diverso per carrier/OEM, numeri privati/gestiti fuori regola
**Hazardous Situation:** L'utente continua a ricevere disturbi, percepisce l'app come inutile anche se whitelist/blacklist sono corrette
**Potential Harm:** Perdita di valore promesso, recensioni negative, abbandono; in casi limite esposizione a truffe telefoniche (vishing)

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Check onboarding obbligatorio del ruolo di call screening con stato visibile e deep-link alle impostazioni; blocco delle funzioni finché il ruolo non è attivo (RF-1)
- `CallScreeningService` nativo snello: solo lookup rubrica/whitelist/blacklist in memoria/cache, nessuna I/O lenta nel percorso critico; rispetto del timeout di piattaforma (NFR affidabilità)
- Blacklist applicata sempre e in modo deterministico (RF-6); test su Android 10+ e principali OEM
- Diagnostica in-app: "ultimo screening riuscito/fallito" con motivo (ruolo mancante, timeout, numero anonimo)
- Future: reportistica di efficacia filtraggio per release successive

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **3 — Remote** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
Il filtraggio resta best-effort per limiti di piattaforma non eliminabili; il beneficio (riduzione misurabile dei disturbi quando il ruolo è attivo) giustifica il residuo. Accettato ALARP con diagnostica trasparente verso l'utente.

**Traceability:** RF-1 · RF-2 · RF-5 · RF-6

---

## RSK-103

**Category:** Privacy — PII Exposure in Logs
**Hazard:** Numeri di telefono (PII) finiscono nei log operativi o diagnostici
**Source of Hazard:** Log di debug del percorso screening/SMS che stampano numero chiamante, contenuto SMS o dump rubrica senza mascheramento
**Hazardous Situation:** Chi accede ai log (sviluppo, crash report, assistenza) vede PII; se i log lasciano il dispositivo si configura data breach
**Potential Harm:** Violazione GDPR, sanzioni, perdita di fiducia; non conformità al NFR "nessun dato lascia il dispositivo, nessun PII nei log"

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **4 — Occasional** · Score: **12** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Divieto di PII nei log: numeri sempre mascherati/hashati (es. ultime 2 cifre o hash), mai contenuto SMS né nomi rubrica; review statica dei punti di log nel canale nativo↔Flutter
- Persistenza solo on-device, nessun backend/sync (fuori perimetro); crash report senza payload telefonici
- Test automatico che asserisce assenza di pattern telefonici nei log di test
- Informativa privacy e consenso esplicito per lettura rubrica, screening chiamate e invio/lettura SMS

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3 · RF-4 · RF-7

---

## RSK-104

**Category:** Compliance — Rigetto Google Play per permessi SMS/telefono
**Hazard:** App rifiutata o rimossa da Google Play per uso di permessi restricted
**Source of Hazard:** `SEND_SMS` e `RECEIVE_SMS` sono permessi restricted che richiedono core-functionality giustificata e declaration approvata; anche lettura registro chiamate e ruolo screening sono sotto scrutinio
**Hazardous Situation:** A ridosso del lancio la pubblicazione è bloccata; servono rework (rimozione SMS automatico) o distribuzione solo sideload con crollo dell'acquisizione
**Potential Harm:** Ritardo go-to-market, costi di rilavorazione, riduzione drastica della base installata

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **5 — Probable** · Score: **15** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Disegno "SMS come core feature" documentato fin da ora: rifiuto + SMS + classificazione sono il cuore del prodotto, non funzioni accessorie; testi di giustificazione Play preparati prima dello sviluppo UI
- Configurazione RF-6 (blacklist senza SMS secondo configurazione) e testo SMS modificabile (RF-9) per dimostrare controllo utente e trasparenza
- Piano B definito: se la declaration è rifiutata, fallback a sola notifica/bozza SMS senza invio automatico, dietro gate di Change Request (non cambio silenzioso di scope)
- Verifica pre-submit dei permessi minimi necessari e matrice permessi vs feature

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **2 — Unlikely** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
L'SMS automatico è il differenziatore centrale di Call Guard; il rischio residuo di rigetto, ridotto da giustificazione anticipata e piano B, è tollerabile in ALARP rispetto al valore utente. Go/no-go Play verificato prima della release 1.0.

**Traceability:** RF-4 · RF-6 · RF-9

---

## RSK-105

**Category:** Economico/Operativo — Invio SMS incontrollato o fallito
**Hazard:** SMS automatico inviato quando non dovuto, duplicato, o mai inviato senza che l'utente lo sappia
**Source of Hazard:** Assenza di sim/credito, modalità aereo, roaming, doppia SIM, retry aggressivi, regola blacklist/SMS fraintesa
**Hazardous Situation:** Utente paga SMS indesiderati (anche verso estero/premium in casi limite) oppure il chiamante legittimo non riceve mai la richiesta di identificazione
**Potential Harm:** Costi diretti, controversie con l'operatore, chiamate legittime perse definitivamente

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Un solo SMS per evento di rifiuto (idempotenza su numero+timestamp), nessun retry automatico silenzioso; stato invio (inviato/fallito) registrato per ogni tentativo (RF-3)
- Rispetto configurazione blacklist con/senza SMS (RF-6); nessun SMS verso numeri anonimi o non richiamabili
- Testo default precompilato e modificabile con contatore lunghezza/costo stimato (RF-9); avviso esplicito su costi operatore al primo avvio
- Gestione errori surface in UI: "SMS non inviato — tocca per riprovare"

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3 · RF-4 · RF-6 · RF-9

---

## RSK-106

**Category:** Data Integrity — Perdita di cronologia e liste (whitelist/blacklist)
**Hazard:** Cronologia chiamate, whitelist, blacklist o testo SMS personalizzato vanno persi o si corrompono
**Source of Hazard:** Scrittura non atomica su storage locale, migrazione schema errata, cancellazione cache da parte di cleaner/OEM, crash durante `RF-10` (aggiornamento immediato)
**Hazardous Situation:** Dopo un riavvio o aggiornamento lo screening si comporta in modo sbagliato (blocca amici o lascia passare spammer) senza che l'utente se ne accorga
**Potential Harm:** Ritorno dei disturbi o blocco di contatti fidati; necessità di ricostruire manualmente le liste; sfiducia

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **4 — Occasional** · Score: **8** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Storage locale con scritture atomiche/transazionali e backup pre-migrazione; le decisioni whitelist/blacklist aggiornano comportamento solo dopo commit confermato (RF-10)
- Liste gestibili con modifica profilo (nome, note, categoria, data aggiunta) e rimozione esplicita con conferma (RF-8)
- Test di persistenza al riavvio e di migrazione schema; export/import locale opzionale
- Future: cestino/undo per rimozioni accidentali

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **1 — Unbelievable** · Score: **2** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3 · RF-8 · RF-10

---

## RSK-107

**Category:** Usabilità/Sicurezza — Errata classificazione e intercettazione SMS fraintesa
**Hazard:** Utente mette in blacklist un numero legittimo (o in whitelist uno spammer) / fraintende quali SMS l'app legge
**Source of Hazard:** CTA Accetta/Rifiuta troppo vicine o ambigue nella vista SMS (RF-7), profilo numero povero, lettura SMS all'apertura app percepita come sorveglianza
**Hazardous Situation:** Contatto importante bloccato a lungo termine oppure spammer sbloccato; allarme privacy con disinstallazione e segnalazioni
**Potential Harm:** Danno relazionale/economico da blocco errato; reclami privacy e danno reputazionale

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **4 — Occasional** · Score: **8** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- CTA distinte e con conferma ("Accetta — riceverai le sue chiamate" / "Rifiuta — le sue chiamate saranno bloccate"), undo immediato, profilo numero modificabile con note e categoria (RF-8)
- Intercettazione SMS solo all'apertura dell'app e limitata alla vista dedicata (RF-7); copy trasparente su cosa viene letto e che tutto resta on-device
- Filtro di ricerca e ordinamento per tenere leggibili cronologia e liste (NFR usabilità)
- Future: proposta di classificazione con motivazione (es. "ha risposto con identificazione completa")

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-7 · RF-8 · RF-10

---

## Risk Summary Table

| RSK ID | Category | Hazard | Potential Harm | Initial Region | Mitigations | Residual Region |
|---|---|---|---|---|---|---|
| RSK-101 | Funzionale — Falso positivo | Rifiuto automatico di chiamata legittima urgente da numero nuovo | Chiamata critica persa; danno economico/disservizio; sfiducia | [ALTO] Intolerable (15) | SMS di recupero + stato invio; CTA whitelist immediate; registro con notifica; onboarding numeri critici | [MEDIO] Conditionally Tolerable (9) |
| RSK-102 | Funzionale — Falso negativo | Spam squilla nonostante l'app | Valore promesso mancato; abbandono; esposizione a vishing | [MEDIO] Conditionally Tolerable (10) | Check ruolo screening; screening nativo snello entro timeout; diagnostica; test OEM | [MEDIO] Conditionally Tolerable (6) |
| RSK-103 | Privacy — PII Exposure in Logs | PII (numeri/SMS) nei log | Breach GDPR; sanzioni; perdita fiducia | [ALTO] Intolerable (12) | Mascheramento PII; solo on-device; test assenza PII nei log; consenso esplicito | [BASSO] Broadly Tolerable (3) |
| RSK-104 | Compliance — Google Play | Rigetto per SEND_SMS/RECEIVE_SMS restricted | Blocco lancio; rework; distribuzione ridotta | [ALTO] Intolerable (15) | Giustificazione core-feature anticipata; opzione blacklist senza SMS; piano B con Change Request | [MEDIO] Conditionally Tolerable (6) |
| RSK-105 | Economico — SMS | SMS duplicato/non dovuto o mai inviato | Costi operatore; chiamante legittimo perso | [MEDIO] Conditionally Tolerable (10) | Idempotenza 1 SMS/evento; stato invio in lista; rispetto config blacklist; avviso costi | [BASSO] Broadly Tolerable (4) |
| RSK-106 | Data Integrity — Persistenza | Perdita/corruzione cronologia e liste | Screening errato dopo riavvio; ricostruzione manuale | [MEDIO] Conditionally Tolerable (8) | Scritture atomiche; commit prima di RF-10; test riavvio/migrazione; conferme di rimozione | [BASSO] Broadly Tolerable (2) |
| RSK-107 | Usabilità/Sicurezza — Classificazione | Whitelist/blacklist errata; SMS percepiti come sorveglianza | Blocco di contatti fidati / sblocco spammer; reclami privacy | [MEDIO] Conditionally Tolerable (8) | CTA con conferma + undo; profilo modificabile; lettura SMS solo in-app e trasparente | [BASSO] Broadly Tolerable (4) |

Nessun rischio residuo [ALTO]. I tre rischi [MEDIO] residui (RSK-101, RSK-102, RSK-104) sono accettati in ALARP per il beneficio utente documentato e richiedono monitoraggio post-lancio (tasso falsi positivi/negativi, esito declaration Play).

---

## 4. Rischi esplicitamente non coperti / out of scope

- iOS, cloud/backend, sync multi-dispositivo, chiamate in uscita: fuori perimetro da brief, nessun rischio valutato qui.
- Contenuto malevolo degli SMS (phishing via testo): mitigato solo tramite classificazione manuale; nessun filtro anti-phishing automatico in scope.

---

*End of Document — CG-RSK-001 v0.1.0*
*Next in package: CG-SRS-001 — Software Requirements Specifications*
