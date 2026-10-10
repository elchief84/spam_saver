# Call Guard — Risk Analysis (ISO 14971)

**Document ID:** CG-RSK-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Standard:** ISO 14971:2019 (metodo adattato — Call Guard non è SaMD/MDSW, vedi CG-OVW-001 §2.3)
**Last Updated:** 2026-10-10
**Trace Parents:** CG-OVW-001 · CG-UC-001

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
| 0.1.0 | 2026-10-10 | Aldo (PM) | Initial draft da brief Call Guard (RF-1…RF-10), CG-OVW-001, CG-UC-001 |

---

## Evaluation Matrix

| **Probability \ Severity** | **Catastrophic (4)** | **Critical (3)** | **Marginal (2)** | **Negligible (1)** |
|---|---|---|---|---|
| **Frequent (6)** | [ALTO] 24 | [ALTO] 18 | [ALTO] 12 | [MEDIO] 6 |
| **Probable (5)** | [ALTO] 20 | [ALTO] 15 | [MEDIO] 10 | [MEDIO] 5 |
| **Occasional (4)** | [ALTO] 16 | [ALTO] 12 | [MEDIO] 8 | [BASSO] 4 |
| **Remote (3)** | [ALTO] 12 | [MEDIO] 9 | [MEDIO] 6 | [BASSO] 3 |
| **Unlikely (2)** | [MEDIO] 8 | [MEDIO] 6 | [BASSO] 4 | [BASSO] 2 |
| **Unbelievable (1)** | [BASSO] 4 | [BASSO] 3 | [BASSO] 2 | [BASSO] 1 |

**Severity Scale (adattata a Call Guard, app consumer non medicale):**

| Level | Label | Description |
|---|---|---|
| 4 | Catastrophic | Perdita sistematica di comunicazioni critiche con danno grave (es. emergenze, rapporti di lavoro), oppure data breach esteso / ban definitivo dallo Store |
| 3 | Critical | Perdita ripetuta di chiamate legittime, invii SMS indesiderati con costi/reclami, violazione GDPR, rifiuto pubblicazione su Play |
| 2 | Marginal | Singolo spam passato, singolo SMS non inviato, singolo falso blocco recuperabile, degrado UX senza perdita dati |
| 1 | Negligible | Fastidio cosmetico, stato vuoto ambiguo, rumore diagnostico senza PII né impatto funzionale |

**Probability Scale (adattata all'uso quotidiano dell'app):**

| Level | Label | Description |
|---|---|---|
| 6 | Frequent | Può accadere a ogni utilizzo o entro giorni su base installata |
| 5 | Probable | Probabile; può accadere più volte in 1–2 anni per singolo utente |
| 4 | Occasional | Verosimile; può accadere poche volte in 2–5 anni per singolo utente |
| 3 | Remote | Non atteso; può accadere una volta in 5–30 anni di uso singolo |
| 2 | Unlikely | Sorprenderebbe se accadesse con le mitigazioni attive |
| 1 | Unbelievable | Sorprenderebbe moltissimo se accadesse con le mitigazioni attive |

**Risk Score = Probability × Severity**

**Acceptability:**

| Colour | Region | Score Range | Action Required |
|---|---|---|---|
| [ALTO] Red | Intolerable | ≥ 12 | Mitigazioni obbligatorie prima del rilascio |
| [MEDIO] Yellow | Conditionally Tolerable | 5 – 11 | Revisione ALARP; confronto benefici–rischi; accettazione solo con giustificazione |
| [BASSO] Green | Broadly Tolerable | ≤ 4 | Rischio residuo accettabile; nessuna azione ulteriore |

> **ALARP note:** I rischi residui [MEDIO] non ulteriormente riducibili sono confrontati con il beneficio operativo (zero squilli da sconosciuti, traccia consultabile, classificazione in 2 tap). Se il beneficio supera il rischio, il rischio è accettato come tollerabile. Se il rischio supera il beneficio, scala a Intolerable.
> Il rischio residuo NON deve restare [ALTO] Intolerable. Se resta [ALTO], servono mitigazioni aggiuntive prima dell'approvazione.

---

## RSK-101 — Blocco di chiamata legittima (falso positivo)

**Category:** Functional — Call Filtering Error
**Hazard:** Una chiamata legittima viene rifiutata automaticamente.
**Source of Hazard:** Matching rubrica/whitelist errato o illeggibile al momento dello screening: normalizzazione mancante (+39, spazi, trattini), rubrica non ancora sincronizzata, contatto aggiunto dopo il rifiuto, lista corrotta o non leggibile entro il timeout.
**Hazardous Situation:** L'utente non riceve una chiamata attesa (familiare, cliente, medico, corriere); vede solo a posteriori la voce in registro.
**Potential Harm:** Perdita di comunicazione importante con danno lavorativo o personale; perdita di fiducia nel filtro; l'utente disinstalla o disattiva la protezione.

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **4 — Occasional** · Score: **12** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Ordine di verifica deterministico in UC-01: anonimo → passa; rubrica o whitelist → passa (RF-5); blacklist → rifiuta (RF-6); solo numero visibile non noto → rifiuta (RF-2).
- Normalizzazione numeri a formato canonico (E.164, strip spazi/trattini, gestione prefisso +39/0) prima di ogni confronto; test dedicati su formati italiani e internazionali.
- Fail-open su errore o timeout imminente: se le liste non sono leggibili, la chiamata passa e l'evento è registrato come "non filtrata per errore" (UC-01 unhappy path).
- Onboarding UC-09: nessun rifiuto senza ruolo e permessi effettivi; stato "non protetto" onesto.
- Registro UC-02 con dettaglio completo per recupero (richiamata manuale).

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **2 — Unlikely** · Score: **6** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
Il beneficio (zero interruzioni da sconosciuti, traccia sempre recuperabile, fail-open che privilegia il passaggio delle legittime) supera il rischio residuo di un singolo falso blocco recuperabile dal registro. Le chiamate critiche ripetute vengono protette definitivamente con un tap in whitelist (RF-10).

**Traceability:** RF-1, RF-2, RF-5, RF-10 · UC-01, UC-02, UC-06, UC-09

---

## RSK-102 — Mancato blocco di spam (falso negativo)

**Category:** Functional — Call Filtering Error
**Hazard:** Una chiamata indesiderata da numero sconosciuto fa squillare il telefono.
**Source of Hazard:** Varianti carrier/vendor nel recapito del numero, timeout di screening superato per lavoro pesante nel callback, numero anonimo non coperto da regola, whitelist inquinata da decisione errata precedente.
**Hazardous Situation:** L'utente viene interrotto da spam o chiamata ambigua nonostante la protezione dichiarata attiva.
**Potential Harm:** Disturbo, perdita del beneficio promesso, sfiducia; nessun danno economico o privacy diretto.

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Screening snello nel CallScreeningService nativo: solo lookup in memoria, nessuna I/O pesante nel callback; persistenza e invio SMS in asincrono (CG-OVW-001 P-02).
- Regola anonimi esplicita: i numeri nascosti passano e non sono registrati come "rifiutate" (nessuna promessa falsa).
- Test su Android 10+ e vendor diversi; verifica del comportamento entro timeout di piattaforma.
- Registro onesto: evento non filtrato marcato "non filtrata per errore" invece di silenzio.
- Blacklist con effetto immediato (RF-10) per chiudere il buco dopo la prima occorrenza.

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-1, RF-2, RF-6, RF-10 · UC-01, UC-02, UC-07

---

## RSK-103 — PII nei log ed esposizione numeri di telefono

**Category:** Privacy — PII Exposure in Logs
**Hazard:** Numeri di telefono o contenuti SMS finiscono in log, crash report o schermate diagnostiche.
**Source of Hazard:** Log di debug che stampano numero chiamante, corpo SMS o record intero; export diagnostico senza redazione; screenshot con PII condivisi dall'utente.
**Hazardous Situation:** Chi ha accesso ai log (sviluppatore, strumento crash, altro utente del dispositivo) legge PII senza necessità.
**Potential Harm:** Violazione GDPR (i numeri sono dati personali), reclamo del chiamante, sanzione, perdita di fiducia; nessun dato sanitario coinvolto.

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **4 — Occasional** · Score: **12** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Divieto di PII nei log: solo hash troncato o flag (es. `known=true/false`, `sms=sent/failed`) e codici esito; mai numero in chiaro né corpo SMS (CG-OVW-001 P-04, UC-02 postcondition).
- Nessuna rete/backend: tutti i dati restano on-device; nessun crash report con PII verso terzi.
- Revisione statica dei punti di log + test automatico che asserisce assenza di pattern telefonici nei log di test.
- Informativa privacy in onboarding UC-09: PII solo on-device, base giuridica uso personale/domestico e legittimo interesse, conservazione locale.

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** NFR privacy/persistenza · UC-01, UC-02, UC-03, UC-09

---

## RSK-104 — Rifiuto pubblicazione Play per permessi SMS restricted

**Category:** Compliance — Store Policy Rejection
**Hazard:** Google Play rifiuta l'app o un aggiornamento per uso di SEND_SMS / RECEIVE_SMS.
**Source of Hazard:** SEND_SMS e RECEIVE_SMS sono permessi "restricted": richiedono core purpose approvato e dichiarazione d'uso; la "risposta automatica a chiamata rifiutata" potrebbe non essere giudicata core purpose sufficiente.
**Hazardous Situation:** Al submit, Play blocca la release; l'app non raggiunge gli utenti o resta ferma a una versione vecchia.
**Potential Harm:** Impossibilità di distribuzione sul canale principale, costi di rilavorazione, distribuzione alternativa meno sicura (sideload) o taglio di funzione.

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **5 — Probable** · Score: **15** → [ALTO] **Intolerable**

**Risk Reduction Measures:**
- Permessi minimi e dichiarati: solo telefono/SMS/rubrica/screening necessari a RF-1…RF-9, con motivazione in-app e dichiarazione Play pronta (CG-OVW-001 C-02, P-07).
- Design che isola l'SMS: rifiuto e registro funzionano anche senza SEND_SMS (degrado onesto UC-09: "senza SEND_SMS nessun SMS automatico").
- Piano B definito prima del submit: se rifiutato, distribuzione fuori Play oppure variante con SMS disabilitato — decisione PM (Q-04 in CG-OVW-001), mai sblocco silenzioso di permessi extra.
- Test di policy pre-submit: verifica che nessun SDK o libreria richieda permessi SMS aggiuntivi.

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **3 — Remote** · Score: **9** → [MEDIO] **Conditionally Tolerable**

**Benefit–Risk Justification:**
L'SMS automatico è il canale che rende il filtro recuperabile per i legittimi (senza, i chiamanti buoni restano senza risposta). Il rischio residuo dipende da decisione esterna (Google) non eliminabile dal software; è accettato perché esiste un degrado onesto (solo registro + screening) che preserva metà del valore anche in caso di rifiuto.

**Traceability:** RF-4, RF-7 · UC-03, UC-05, UC-09

---

## RSK-105 — Falsa sensazione di protezione (ruolo/permessi mancanti o revocati)

**Category:** Usability — Misleading Protection State
**Hazard:** L'app mostra o lascia intendere "protezione attiva" mentre screening o SMS non possono funzionare.
**Source of Hazard:** Ruolo ROLE_CALL_SCREENING non assegnato, permesso revocato dal sistema dopo l'onboarding, dispositivo non supportato (< Android 10 o ROM senza ruolo), stato UI non ricontrollato alla riapertura.
**Hazardous Situation:** L'utente ignora chiamate pensando "tanto filtra lui" oppure si lamenta di spam convinto di essere protetto; in alternativa crede che l'SMS parta mentre SEND_SMS è revocato.
**Potential Harm:** Chiamate indesiderate che passano inosservate, risposte SMS mai inviate scambiate per inviate, supporto e recensioni negative.

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **5 — Probable** · Score: **10** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- UC-09 come gate onesto: stato "protezione attiva" solo con ruolo + permessi minimi reali; altrimenti "non protetto / protezione sospesa" con azione di completamento.
- Ricontrollo a ogni apertura: ruolo e permessi riverificati, UC-01 in fail-open (lascia passare) finché non tornano.
- Messaggi granulari: "senza SEND_SMS nessun SMS automatico", "dispositivo non supportato" invece di finta protezione.
- Nessuna promessa su anonimi: comunicato che passano sempre.

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** NFR affidabilità · UC-01, UC-09

---

## RSK-106 — Invio SMS indesiderato, fallito o in loop

**Category:** Functional — Unwanted or Failed Auto-Reply
**Hazard:** L'SMS automatico parte quando non dovrebbe, non parte quando dovrebbe, o parte più volte.
**Source of Hazard:** Regola blacklist ambigua ("secondo configurazione" RF-6 senza default deciso), testo vuoto o oltre limite, assenza segnale/credito, retry aggressivo, doppio trigger sullo stesso rifiuto.
**Hazardous Situation:** Il chiamante riceve un messaggio confuso o multiplo (percepito come spam, con costo a carico utente), oppure il legittimo non riceve nulla ma il registro dice "inviato".
**Potential Harm:** Costi SMS, blocco carrier per spam, reclami, perdita del canale di identificazione; danno marginale ma ripetibile.

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **4 — Occasional** · Score: **8** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Singolo invio per rifiuto, nessun retry in loop: fallimento marcato "SMS non inviato + motivo" visibile in UC-02; policy di retry esplicita solo da decisione PM (Q-03).
- Validazione template UC-04: blocco salvataggio se vuoto o oltre limite; blocco invio se testo vuoto con avviso alla riapertura; ultimo testo valido sempre attivo.
- Default blacklist prudente: nessun SMS ai numeri in blacklist salvo attivazione esplicita (da confermare in Q-01); mai invio a numeri non mobili.
- Registro onesto UC-03: stati distinti "inviato / non inviato / non previsto da configurazione", mai "inviato" ingannevole.

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-3, RF-4, RF-6, RF-9 · UC-02, UC-03, UC-04

---

## RSK-107 — Perdita o corruzione dati locali dopo riavvio o crash

**Category:** Data Integrity — Local Persistence Loss
**Hazard:** Cronologia, whitelist, blacklist o template SMS persi o troncati dopo riavvio, aggiornamento o crash durante scrittura.
**Source of Hazard:** Scritture non atomiche, salvataggio template interrotto, migrazione schema senza rollback, cancellazione cache aggressiva dal sistema.
**Hazardous Situation:** Dopo il riavvio l'utente ritrova liste vuote o template troncato: legittimi ribloccati, spam risbloccato, SMS con testo mozzato.
**Potential Harm:** Rilavorazione (riclassificare tutto), nuovo ciclo di falsi positivi/negativi, sfiducia nella persistenza promessa dal brief.

**Initial Risk Evaluation:**
Severity: **3 — Critical** · Probability: **3 — Remote** · Score: **9** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Scritture atomiche: ultimo salvataggio valido sempre integro; template troncato mai attivato (UC-04 unhappy path); data di aggiunta immutabile alla modifica profilo (UC-08).
- Storage locale transazionale (Room/SharedPreferences con apply/commit verificato); test di riavvio e kill durante scrittura.
- Isolamento guasti UC-02: record illeggibile non cancella gli altri; errore di lettura mostrato invece di lista vuota silenziosa.
- Nessuna dipendenza rete: nessun conflitto sync che possa sovrascrivere il locale.

**Residual Risk Status (Post Mitigation):**
Severity: **3 — Critical** · Probability: **1 — Unbelievable** · Score: **3** → [BASSO] **Broadly Tolerable**

**Traceability:** NFR persistenza · UC-02, UC-04, UC-06, UC-07, UC-08

---

## RSK-108 — Classificazione errata da vista SMS (whitelist a spammer / blacklist a legittimo)

**Category:** Usability — Misclassification by User
**Hazard:** Per fretta o messaggio ambiguo, l'utente promuove uno spammer o bandisce un legittimo con un tap.
**Source of Hazard:** CTA Accetta/Rifiuta adiacenti, doppio tap, messaggio di identificazione vago ("sono io, richiamami"), numero spostato mentre il dettaglio è aperto, nessuna conferma né memoria del motivo.
**Hazardous Situation:** Dalla chiamata successiva la regola sbagliata è già attiva (RF-10): lo spam passa sempre o il legittimo viene sempre rifiutato.
**Potential Harm:** Filtro avvelenato da un singolo tap; per accorgersene serve un nuovo ciclo chiamata → registro → riclassificazione.

**Initial Risk Evaluation:**
Severity: **2 — Marginal** · Probability: **4 — Occasional** · Score: **8** → [MEDIO] **Conditionally Tolerable**

**Risk Reduction Measures:**
- Conferma di spostamento tra liste opposte e avviso "ultima decisione vince"; mai doppia presenza (UC-05, UC-06, UC-07).
- Operazioni idempotenti contro doppio tap; rimozione/sblocco sempre reversibile.
- Profilo numero con nome, note, categoria e data di aggiunta (UC-08) preservato durante lo spostamento: il motivo resta leggibile tra un mese.
- Dettaglio numero raggiungibile da registro, SMS e liste: riclassificazione in 2 tap senza caccia al numero.

**Residual Risk Status (Post Mitigation):**
Severity: **2 — Marginal** · Probability: **2 — Unlikely** · Score: **4** → [BASSO] **Broadly Tolerable**

**Traceability:** RF-7, RF-8, RF-10 · UC-05, UC-06, UC-07, UC-08

---

## Risk Summary Table

| RSK ID | Category | Hazard | Potential Harm | Initial Region | Mitigations | Residual Region |
|---|---|---|---|---|---|---|
| RSK-101 | Functional — Call Filtering Error | Chiamata legittima rifiutata per matching errato | Perdita comunicazione importante; sfiducia | [ALTO] 12 Intolerable | Ordine deterministico + normalizzazione E.164; fail-open; onboarding; registro recuperabile | [MEDIO] 6 Conditionally Tolerable |
| RSK-102 | Functional — Call Filtering Error | Spam da sconosciuto fa squillare | Disturbo; beneficio mancato | [MEDIO] 10 Conditionally Tolerable | Screening snello async; regola anonimi; test multi-vendor; blacklist immediata | [BASSO] 4 Broadly Tolerable |
| RSK-103 | Privacy — PII Exposure in Logs | Numeri/SMS nei log o diagnostica | Violazione GDPR; reclami | [ALTO] 12 Intolerable | Divieto PII nei log; solo on-device; test assenza pattern; informativa | [BASSO] 3 Broadly Tolerable |
| RSK-104 | Compliance — Store Policy Rejection | Play rifiuta SEND_SMS/RECEIVE_SMS | No distribuzione; rilavorazione | [ALTO] 15 Intolerable | Permessi minimi; degrado onesto; piano B; pre-submit check | [MEDIO] 9 Conditionally Tolerable |
| RSK-105 | Usability — Misleading Protection State | Finta "protezione attiva" senza ruolo/permessi | Spam inosservato; SMS creduti inviati | [MEDIO] 10 Conditionally Tolerable | Gate UC-09; ricontrollo on-open; fail-open; messaggi granulari | [BASSO] 4 Broadly Tolerable |
| RSK-106 | Functional — Unwanted or Failed Auto-Reply | SMS multiplo, mancato o ingannevole | Costi; blocco carrier; canale perso | [MEDIO] 8 Conditionally Tolerable | Invio singolo senza loop; validazione template; default blacklist no-SMS; stati onesti | [BASSO] 4 Broadly Tolerable |
| RSK-107 | Data Integrity — Local Persistence Loss | Liste/cronologia/template persi al riavvio | Riclassificare tutto; refalsi positivi/negativi | [MEDIO] 9 Conditionally Tolerable | Scritture atomiche; test kill/riavvio; isolamento record guasti; no sync | [BASSO] 3 Broadly Tolerable |
| RSK-108 | Usability — Misclassification by User | Whitelist a spammer / blacklist a legittimo | Filtro avvelenato da un tap | [MEDIO] 8 Conditionally Tolerable | Conferma spostamento; idempotenza; profilo con note preservato; riclassifica in 2 tap | [BASSO] 4 Broadly Tolerable |

---

## Open Risks & Decisions (input a PM)

- Q-01 / RSK-106: default invio SMS per blacklist (proposto: disattivato). Da decidere entro 2026-10-17.
- Q-02 / RSK-102: trattamento anonimi confermato "passano sempre"; qualsiasi cambio richiede Change Request e rivalutazione RSK-101/102.
- Q-03 / RSK-106: policy retry SMS (proposto: nessun retry automatico, stato visibile). Da decidere entro 2026-10-17.
- Q-04 / RSK-104: giustificazione Play e piano B distribuzione. Da decidere entro 2026-10-24.
- Nessun rischio residuo [ALTO]: RSK-101 e RSK-104 restano [MEDIO] con giustificazione benefici–rischi; approvazione possibile senza mitigazioni aggiuntive salvo richiesta reviewer.

---

*End of Document — CG-RSK-001 v0.1.0*
*Next in package: CG-SRS-001 — Software Requirements Specifications*
