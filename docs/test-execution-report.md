# Call Guard — Test Execution Report

**Document ID:** CG-TER-001
**Version:** 0.1.0
**Status:** Draft
**Service:** `call-guard`
**Execution Date:** 2026-10-11
**Trace Parents:** CG-TP-001 · CG-SRS-001 · CG-SDS-001 · CG-ARCH-001 · CG-RSK-001 · CG-TRM-001 · CG-QAR-001

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Aldo (PM) | 2026-10-11 | Aldo |
| Reviewer | — | — | — |
| Approver (QA/RA) | — | — | — |

### Change History

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-11 | Aldo (PM) | Initial draft — esecuzione registrata su workspace senza build: 0/44 TP eseguiti, verdetto FAIL bloccante |

---

## 1. Executive Summary

Questo documento registra l'esito formale dell'esecuzione dei test per `call-guard` (app Android-only: modulo nativo Kotlin `CallScreeningService` + ruolo `ROLE_CALL_SCREENING`, Android 10+; UI Flutter + platform channel; persistenza solo on-device in Room/prefs) a fronte di CG-TP-001 v0.1.0 e dell'implementazione descritta in CG-SDS-001 v0.1.0 / CG-ARCH-001 v0.1.0.

Al 2026-10-11 **non esiste alcun artefatto eseguibile nel workspace** (solo `README.md` + `docs/`, nessun `*.kt`/`*.dart`, nessun APK, nessuna pipeline CI — accertato in CG-QAR-001 QA-V-011). Di conseguenza **nessun caso dinamico di CG-TP-001 è eseguibile**: tutti i livelli UT/IT/E2E/PERF/SEC/COMP/CMPT restano in stato Not Run. Le uniche verifiche svolte sono quelle statiche documentali già registrate in CG-QAR-001 (12 controlli QA-V-001…QA-V-012), qui richiamate come evidenza e non come sostituzione dell'esecuzione.

| Metric | Result |
|---|---|
| Total Test Cases (definiti in CG-TP-001 §4) | 44 verificati per enumerazione (vedi nota conteggio sotto) |
| Passed | 0 |
| Failed (dinamico) | 0 — nessun test eseguito, quindi nessun pass/fail dinamico assegnabile |
| Not Run / Blocked | 44 |
| Skipped (per disegno) | 0 |
| Test Suite Duration | N/A — nessuna suite avviata |
| Kotlin / Flutter compile (`./gradlew test`, `flutter test`) | NOT RUN — nessun sorgente da compilare |
| Overall Line Coverage | 0% — nessuno strumento di coverage avviato (nessun codice) |
| Overall Branch Coverage | 0% |
| Overall Function Coverage | 0% |
| Overall Statement Coverage | 0% |

**Nota conteggio:** CG-TRM-001 §4 dichiara "46 TP" e CG-TP-001 §1/§5 dichiara "38 requisiti". L'enumerazione reale è **44 TP** (TP-101…103, 201…203, 301…307, 401…403, 501…503, 601…604, 701…705, 801…802, 901…902, 1001…1005, 1101…1104, 1201…1203) e **37 SRS** (SRS-101…SRS-1005 per `grep -c '^### SRS-'` = 37). Lo scostamento è registrato come difetto documentale QF-003 in §7, non come test mancante: ogni SRS reale ha almeno un TP.

**Coverage verdict: FAIL.** Nessuna soglia è soddisfatta; non esistono "accepted gap" di coverage — esiste un blocco totale di esecuzione (GAP-01 di CG-TRM-001 resta Open). I cinque gate di release definiti in CG-TP-001 §6 (TP-1003 zero-PII-nei-log, TP-301/TP-1202 timeout/ruolo/OEM, TP-1201 persistenza/migrazione, TP-1203 policy Play, TP-1101 falso-positivo 10/10) sono tutti **red-by-absence**. Nessuna approvazione di release è possibile su questa base.

---

## 2. Test Environment

| Attribute | Value |
|---|---|
| Execution Date | 2026-10-11 |
| Host OS | macOS (host documentale; esecuzione on-device non avviata) |
| Target Runtime (pianificato, non eseguito) | Android 10 (API 29) … Android 15 (API 35); Kotlin + Flutter stable corrente; Room per `rejected_calls` / `trusted_entries` / `sms_triage`; DataStore/SharedPreferences per `cg_sms_template_text` e `cg_blacklist_sms_enabled` |
| Device Matrix (pianificata, non eseguita) | 1 Pixel (riferimento AOSP) + 1 device OEM con battery-optimizer aggressivo; emulatori API 29, 31, 33, 35; 1 device dual-SIM per AMB-05 best-effort; 2 SIM di laboratorio; run con rete disabilitata e con proxy di cattura |
| Unit Framework (pianificato) | JUnit5 + MockK (Kotlin, decision function / normalizzazione / validazione); `flutter test` (Dart, logica pura) |
| Integration Framework (pianificato) | Robolectric + AndroidX Test; Room in-memory; `FakeSmsManager` (success / `RESULT_ERROR_NO_SERVICE` / `RESULT_ERROR_NULL_PDU`); `FakeContactsProvider`; `FakeCallScreeningCall`; orologio fake |
| E2E Framework (pianificato) | `integration_test` Flutter + Espresso su device fisici ed emulatori |
| Coverage Provider | Nessuno avviato (nessun codice; soglia di riferimento 80% per futuro run) |
| Test Configuration | CG-TP-001 v0.1.0 — 44 casi TP-101…TP-1203; fixture rubrica/liste/numeri-canarino come da CG-TP-001 §3 |
| Architecture Under Test | Clean/Hexagonal — Domain (`:domain` puro Kotlin), Application (use-case contro porte), Infrastructure (adapter nativi + Room + channel + UI Flutter). Nessuna build disponibile |
| Blocco accertato | `ls` mostra solo `README.md` + `docs/`; ricerca `*.kt`/`*.dart`/APK/workflow CI senza risultati; `git status` senza codice tracciato (evidenza in CG-QAR-001 QA-V-011 → QF-004 ALTO) |

Dati di test (non utilizzati in questa esecuzione, riservati al run futuro): rubrica fixture `+39 333 000 0001` / `+39 333 000 0002`, whitelist `+39 333 000 0010`, blacklist `+39 333 000 0020`, sconosciuto `+39 333 000 0030`, short code `40400`, sender alfanumerico `BANCA`, hidden `PRESENTATION_RESTRICTED`. Vietati numeri personali reali.

---

## 3. Test Results by Layer

Nessun test dinamico eseguito. Le tabelle sotto elencano i casi pianificati per layer (raggruppamento per tipo dichiarato in CG-TP-001 §2/§4) con stato uniforme Not Run. Gli ID statici QA-V-* sono verifiche documentali di CG-QAR-001, non esecuzione dei TP.

### 3.1 Domain Layer — Unit Tests (pianificati, non eseguiti)

| Test File / Harness (pianificato) | Test Cases | Passed | TP IDs Covered |
|---|---|---|---|
| `domain/PhoneNumberTest` (JUnit5 + MockK) — normalizzazione, visibilità, dialabilità | 0 eseguiti (4 pianificati) | 0 — Not Run | TP-304, TP-305, TP-302 (parte), TP-703 (parte) |
| `domain/ScreeningDecisionTest` (parametrica 10+6 combo) — precedenza blacklist > pass > reject | 0 eseguiti (2 pianificati) | 0 — Not Run | TP-302, TP-703 |
| `domain/SmsEligibilityTest` + `AutoReplyTemplateTest` — eleggibilità, validazione non-vuoto/limite | 0 eseguiti (3 pianificati) | 0 — Not Run | TP-305, TP-503, TP-103 (parte) |
| `domain/TrustedEntryTest` — mutua esclusione, move registrato | 0 eseguiti (1 pianificato) | 0 — Not Run | TP-702 (parte) |
| **Subtotal** | **0 / 10+ pianificati eseguiti** | **0 — Not Run** | |

### 3.2 Application Layer — Unit + Integration Tests (pianificati, non eseguiti)

| Test File / Harness (pianificato) | Test Cases | Passed | TP IDs Covered |
|---|---|---|---|
| `application/ScreenIncomingCallTest` + `SendAutoReplyTest` (Robolectric, FakeSmsManager, snapshot in-memory) | 0 eseguiti (8 pianificati) | 0 — Not Run | TP-307, TP-501, TP-502, TP-902, TP-1102, TP-302 (parte), TP-306 |
| `application/TriageInboundSmsTest` + `ClassifyNumberTest` + `ManageListsTest` (Room in-memory) | 0 eseguiti (9 pianificati) | 0 — Not Run | TP-601, TP-603, TP-604, TP-701, TP-702, TP-704, TP-1103 |
| `application/RecordRejectedCallTest` + `ConfigureSmsTemplateTest` + `ProtectionStatusTest` | 0 eseguiti (7 pianificati) | 0 — Not Run | TP-101, TP-102, TP-103, TP-201, TP-401, TP-402, TP-503 |
| **Subtotal** | **0 / 24+ pianificati eseguiti** | **0 — Not Run** | |

### 3.3 Infrastructure / Device Layer — Integration, E2E, PERF, SEC, COMP, CMPT (pianificati, non eseguiti)

| Test File / Harness (pianificato) | Test Cases | Passed | TP IDs Covered |
|---|---|---|---|
| E2E device (Espresso + `integration_test`, Pixel + OEM, API 29–35, 2 SIM) — pre-squillo, rifiuto/pass reale, SMS reale su rete di test, triage, CTA, usabilità | 0 eseguiti | 0 — Not Run | TP-202, TP-301, TP-602, TP-704, TP-801, TP-802, TP-901, TP-1101, TP-1103, TP-1104, TP-1202 |
| PERF on-device (`SystemClock.elapsedRealtime`, Trace) + fault injection (aereo, credito assente, storage pieno, revoca a caldo) | 0 eseguiti | 0 — Not Run | TP-301, TP-1001, TP-1004, TP-1202 |
| SEC/COMP (grep canarino su logcat + file log + crash report; cattura proxy DNS/HTTP; review manifest/provider/backup) | 0 eseguiti | 0 — Not Run | TP-1002, TP-1003, TP-901, TP-902 |
| CMPT/COMPAT (API 28 incompatibilità, reboot/update/migrazione Room, checklist declaration Play + fallback solo-rifiuto) | 0 eseguiti | 0 — Not Run | TP-1005, TP-403, TP-705, TP-1201, TP-1203, TP-203 |
| **Subtotal** | **0 / 20 pianificati eseguiti** | **0 — Not Run** | |

**Totale dinamico: 0 passed / 0 failed / 44 Not Run su 44 TP definiti.** Non si registra alcun "Skipped per disegno": tutto è bloccato da QF-004 (manca l'artefatto).

Verifiche statiche disponibili (per tracciabilità, non conteggiate come TP): CG-QAR-001 QA-V-001…QA-V-012 — 9 Pass (di cui 3 solo-statici), 3 Fail + 1 Blocked (vedi §7).

---

## 4. Coverage Analysis

### 4.1 Coverage by Layer

| Layer | Line Coverage | Branch Coverage | Function Coverage | Statement Coverage | Status |
|---|---|---|---|---|---|
| Domain (`SU-DOM-01-01`, `02-01`, `02-02`, `03-01`, `03-02`, `04-01`) | 0% (non misurato) | 0% | 0% | 0% | FAIL — nessun codice, nessuna misura |
| Application (`SU-APP-01-01`…`08-01`) | 0% (non misurato) | 0% | 0% | 0% | FAIL — nessun codice, nessuna misura |
| Infrastructure (`SU-INF-01-01`…`08-01`, UI Flutter) | 0% (non misurato) | 0% | 0% | 0% | FAIL — nessun codice, nessuna misura |
| **Overall** | **0%** | **0%** | **0%** | **0%** | **FAIL — sotto soglia 80%, nessun gap accettato** |

### 4.2 Accepted Coverage Gaps

Nessun gap di coverage accettato in questa fase. L'assenza totale di misura non è un gap accettabile ma un blocco (GAP-01 di CG-TRM-001: "Test Execution — Open, bloccante per Approved").

| File / Component | Uncovered Lines | Reason | Closing Phase | Accepted By |
|---|---|---|---|---|
| Intero prodotto (`call-guard`: tutti i SU di CG-SDS-001 §8–§10) | 100% — tutto non coperto perché non eseguito | Nessuna build disponibile al 2026-10-11 (QF-004); suite UT/IT/E2E mai avviate | Build successiva: rieseguire tutti i 44 TP su matrice Pixel+OEM/API 29–35 e riemettere CG-TER-001 con misure reali | — (nessuna accettazione; approvazione negata fino a TER verde) |

---

## 5. Compliance Test Results

Tutti i casi COMP di CG-TP-001 risultano Not Run dinamicamente. Si riporta per ciascuno lo stato statico corrispondente da CG-QAR-001.

### 5.1 PII in Logs

| Test Case | Result | Notes |
|---|---|---|
| TP-1003 — Nessun PII nei log (grep canarino su logcat + file log + crash report; gate: un solo canarino in chiaro = rosso) | NOT RUN (dinamico) / Statico OK sulla catena spec | Catena SRS-1002/1003/901 → ARCH §9 → SDS §10.8 → TP-1003 verificata staticamente in QA-V-009 (Pass statico). Prova dinamica bloccata da QF-004. Gate di release resta rosso per assenza |
| TP-901 (parte privacy) — Superfici di errore senza PII extra né stack trace | NOT RUN | Regole presenti in SRS-901 + SDS §7; screenshot/logcat futuri richiesti. Bloccato da QF-004 |

### 5.2 Audit Trail Completeness

| Test Case | Result | Notes |
|---|---|---|
| TP-401 — Un record per rifiuto (numero, data/ora, esito, stato SMS, note, origine decisione), mai aggregati | NOT RUN | Invariante definita in SDS §3.1/§8 (SU-DOM-03-01) e verificata staticamente in QA-V-008/V-010. Prova Room futura bloccata |
| TP-402 — Stato SMS aggiornato (sent/failed/skipped+motivo, solo template-ref hash) | NOT RUN | Macchina `pending → sent/failed/skipped`, `failed → sent/failed` una sola volta, terminali `sent/skipped`; verificata staticamente in QA-V-010. Bloccata |
| TP-403 + TP-1201 — Cronologia persiste a reboot/update, ordine discendente; migrazione senza perdite | NOT RUN | Gate di release. Bloccato da QF-004; rischio RSK-106 resta non dimostrato |

### 5.3 Soft Delete Retention

| Test Case | Result | Notes |
|---|---|---|
| N/A dedicato (policy: nessuna cancellazione silenziosa; rimozione da lista mai cancella cronologia — ARCH §9.2, SDS §3) | NOT RUN | Comportamento coperto indirettamente da TP-401/TP-701/TP-705/TP-1201, tutti Not Run. Nessuna potatura silenziosa consentita (TQ-01 open, default keep-until-user-deletes) |

---

## 6. Security Test Results

| Test Case | Result | Notes |
|---|---|---|
| TP-1001 — Screening solo on-device, nessuna chiamata di rete nel path (`onScreenCall` con rete disabilitata + proxy) | NOT RUN | Regola SRS-1001 verificata staticamente (QA-V-009/V-010); parità on/offline e zero-egress da dimostrare con cattura futura. Bloccato |
| TP-1002 — Nessun dato lascia il dispositivo (traffico PII = 0 byte; manifest senza provider esportati; `allowBackup=false` o cifrato; nessun SDK analytics con PII) | NOT RUN | Checklist manifest/backup verde su carta (ARCH §8, SDS §3); prova di rete futura bloccata. RSK-104 resta non dimostrato |
| TP-203/TP-204-equivalente — Feature-gate per permesso negato (READ_CONTACTS / SEND_SMS / SMS-read), nessun crash, messaggio dedicato | NOT RUN | Tre messaggi con azione correttiva definiti in SDS §7; prova negazione singola futura bloccata |
| TP-1004 — Degrado graceful: fail-open chiamate, notifica in-app, nessuno stato parziale (ruolo revocato a caldo, SMS revocato, storage pieno) | NOT RUN | Semantica fail-open/fail-explicit in SRS-1004 + SDS §9; prova fault-injection futura bloccata |

Cross-tenant isolation / session-domain / read-only-caller (righe generiche del template H.Core): **N/A per Call Guard** — nessun backend, nessun multi-tenant, nessun account (vedi CG-RSK-001 §4). Il rischio analogo (accesso di altre app allo store locale) è coperto da TP-1002 sopra.

---

## 7. Failed Tests & Defects

Nessun test dinamico è fallito perché nessun test dinamico è stato eseguito. Si registrano qui i **difetti documentali e il blocco di esecuzione** accertati dalle verifiche statiche di CG-QAR-001, che determinano il verdetto FAIL di questo TER.

| Test Case / Check | Failure / Finding Description | Defect ID | Status | Resolution |
|---|---|---|---|---|
| Blocco esecuzione — 0/44 TP eseguibili, nessun APK/`*.kt`/`*.dart`/CI | Manca l'artefatto: l'intero Test Plan dinamico non è verificato; i 5 gate (TP-301/TP-1202, TP-1003, TP-1201, TP-1203, TP-1101) rossi per assenza | QF-004 (ALTO, da CG-QAR-001) | Open | Richiesta build testabile + esecuzione sulla matrice Pixel+OEM/API 29–35 con logcat, cattura traffico e report gate allegati; riemissione CG-TER-001 |
| TP-101 / TP-1102 — Default SMS "entro 1 segmento GSM-7" | Difetto di specifica: il default è lungo 183 caratteri (`python3 len`), quindi 2 segmenti GSM-7 concatenati, non 1. Il test come scritto andrebbe rosso su implementazione corretta; impatto costi RSK-107 sottostimato | QF-001 (MEDIO) | Open | Decisione PM: (a) abbreviare il default a ≤160 char GSM-7, oppure (b) correggere RSK-107/SDS §4.1/§8.6/TP-101/TP-1102 a "2 segmenti" e riqualificare costi + limite editor 480 char |
| Riferimento SRS-710 in SRS AMB-01 ("vedi SRS-502, SRS-710") | Dangling trace: nessuna sezione `### SRS-710` esiste; riferimento non risolvibile | QF-002 (BASSO) | Open | Correggere il riferimento al requisito toggle reale (SRS-103/SRS-502) in CG-SRS-001 |
| Conteggio "38 requisiti" in CG-TP-001 §1/§5 e CG-ARCH-001 §1.2 | Dato errato: i requisiti reali sono 37 (`grep -c '^### SRS-'` = 37); TRM dichiara inoltre 46 TP contro 44 enumerati | QF-003 (BASSO) | Open | Correggere i claim a 37 SRS / 44 TP (o aggiungere il requisito mancante se caduto); allineare CG-TRM-001 §4 |
| AD-03 / AD-05 / AMB-05 + residui RSK-101/105/109 (ALARP MEDIO) | Decisioni aperte correttamente tracciate ma non chiuse con evidenza device: scope SMS-read vs Consent/Retriever API, fallback disconnect-vs-silence per OEM, affidabilità dual-SIM/carrier | QF-005 (MEDIO) | Open | Chiudere con evidenza TP-1202/TP-1203 o con sign-off ALARP esplicito + KPI (reclami chiamata persa, esito declaration Play, tempo mediano apertura post-rifiuto) |

Nessun record fantasma, nessuno stato parziale, nessun invio SMS osservato: senza build non esiste superficie su cui osservare difetti di codice.

---

## 8. SRS Coverage Summary

| Status | Count |
|---|---|
| SRS requirements with passing test coverage | 0 of 37 |
| SRS requirements with no test coverage (dinamica) | 37 — vedi lista sotto |

Copertura dinamica per SRS (tutte Not Run; mapping TP invariato da CG-TP-001 §5):

| SRS ID | Description | Reason not covered | Closing Phase |
|---|---|---|---|
| SRS-101, SRS-102, SRS-103 | Default/persistenza/toggle SMS | Nessuna build; TP-101/102/103/1102/1201 non eseguiti | Build successiva + TER-002 |
| SRS-201, SRS-202, SRS-203 | Screening nativo / ruolo / permessi | Come sopra; TP-201/202/203/1004/1203 non eseguiti | Come sopra |
| SRS-301, SRS-302, SRS-303, SRS-304, SRS-305, SRS-306, SRS-307 | Screening e rifiuto (timeout, matrice decisione, contatti, anonimi, short-code, blacklist, immediatezza) | Come sopra; TP-301/302/303/304/305/306/307/703/1101/1202 non eseguiti | Come sopra |
| SRS-401, SRS-402, SRS-403 | Registrazione (record per rifiuto, stato SMS, persistenza/ordinamento) | Come sopra; TP-401/402/403/1201 non eseguiti | Come sopra |
| SRS-501, SRS-502, SRS-503 | SMS automatico (exactly-once, skip blacklist, editor validato) | Come sopra; TP-501/502/503/902/1102 non eseguiti | Come sopra |
| SRS-601, SRS-602, SRS-603, SRS-604 | Triage SMS (vista all'apertura, 2 CTA, accetta/rifiuta con source+timestamp) | Come sopra; TP-601/602/603/604/1103/1104 non eseguiti | Come sopra |
| SRS-701, SRS-702, SRS-703, SRS-704, SRS-705 | Liste (CRUD+profilo, mutua esclusione, precedenza, promozione da cronologia, persistenza) | Come sopra; TP-701/702/703/704/705/1201 non eseguiti | Come sopra |
| SRS-801, SRS-802 | Ricerca/liste/dettaglio profilo | Come sopra; TP-801/802 non eseguiti | Come sopra |
| SRS-901, SRS-902 | Error handling (azione correttiva senza PII/stack; un solo retry manuale) | Come sopra; TP-901/902 non eseguiti | Come sopra |
| SRS-1001, SRS-1002, SRS-1003, SRS-1004, SRS-1005 | Cross-cutting (solo on-device, nessun egress, no PII nei log, fail-open, solo Android 10+) | Come sopra; TP-1001/1002/1003/1004/1005/1202 non eseguiti | Come sopra |

Copertura statica (non sostitutiva): ogni SRS ha ≥1 TP mappato (CG-TP-001 §5 OK) e ≥1 SU mappata (CG-SDS-001 §12 / CG-TRM-001 §1–§2 OK); ogni controllo RSK-101…109 ha ≥1 TP (CG-TP-001 §6 OK). Il gap è solo di esecuzione.

---

## 9. Overall Verdict

| Criterion | Result |
|---|---|
| All test cases passed | FAIL — 0/44 eseguiti, 44 Not Run |
| Compilation passes (Kotlin/Flutter) | NOT RUN — nessun sorgente da compilare |
| Overall coverage meets threshold (80%) | FAIL — 0% misurato, nessun gap accettato |
| All risk controls verified (RSK-101…109) | FAIL — controlli definiti e mappati ma non dimostrati dinamicamente; residui MEDIO RSK-101/105/109 in ALARP non verificati |
| No PII in logs (TP-1003 gate) | NOT PROVEN — catena spec verde su carta, prova logcat futura bloccata |
| No off-device leakage (TP-1001/1002) | NOT PROVEN — prova traffico/manifest runtime futura bloccata |

**Overall Verdict: FAIL — esecuzione bloccata, nessuna approvazione di release.**

Motivi bloccanti: (1) QF-004 — manca l'artefatto eseguibile, quindi nessun comportamento osservabile (pre-squillo, rifiuto/pass, invio SMS, CTA triage, persistenza) è verificato e i cinque gate di release sono rossi per assenza; (2) QF-001 — il default SMS da 183 caratteri è venduto come 1 segmento ma ne occupa 2, con impatto su RSK-107 e su TP-101/TP-1102; (3) QF-002/QF-003 — riferimenti e conteggi documentali errati (SRS-710 fantasma; 38 vs 37 SRS; 46 vs 44 TP); (4) QF-005 — AD-03/AD-05/AMB-05 aperti, da chiudere con evidenza device o sign-off ALARP.

Azioni richieste prima della riemissione (CG-TER-002): correggere i documenti (QF-001/002/003), produrre una build testabile, eseguire i 44 TP sulla matrice Pixel+OEM/API 29–35 (con priorità ai gate TP-1003, TP-301/TP-1202, TP-1201, TP-1203, TP-1101), allegare logcat con grep canarino, catture proxy zero-egress, misure p99 `onScreenCall`, report migrazione/reboot e pacchetto declaration Play con demo fallback solo-rifiuto.

---

*End of Document — CG-TER-001 v0.1.0*
