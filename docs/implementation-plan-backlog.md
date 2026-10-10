# Call Guard — Implementation Plan Backlog

**Document ID:** CG-IPB-001
**Version:** 0.1.0
**Status:** Draft
**IEC 62304 Phase:** 5.5 — Software Unit Implementation · 5.6 — Software Integration Testing
**Service:** `call-guard`
**Date:** 2026-10-11

**Trace Parents:**
- CG-SRS-001 — Software Requirements Specifications v0.1.0 (38 requisiti, SRS-101…SRS-1005)
- CG-ARCH-001 — Software Architecture v0.1.0 (6 SI, 22 SU, tutte Classe A)
- CG-SDS-001 — Software Design Specification v0.1.0 (§2–§11, contratto `call_guard/bridge_v1`)
- CG-TP-001 — Test Plan v0.1.0 (TP-101…TP-1203)
- CG-RSK-001 — Risk Analysis (RSK-101…RSK-109) · CG-UC-001 (UC-01…UC-08) · CG-UN-001

---

## Document Control

| Role | Name | Date | Signature |
|---|---|---|---|
| Author | Aldo (PM) | 2026-10-11 | Aldo |
| Technical Reviewer | Onofrio (TA) | 2026-10-11 | — |
| Approver (QA/RA) | TBD | — | — |

### Change Log

| Version | Date | Author | Summary of Change |
|---|---|---|---|
| 0.1.0 | 2026-10-11 | Aldo (PM) | Initial draft — backlog eseguibile da CG-SRS/CG-ARCH/CG-SDS/CG-TP; 26 task stimati con acceptance criteria e dipendenze |

---

## 1. Purpose & Scope

Questo documento è il backlog di implementazione sequenziato e atomico di **Call Guard** (app Android-only: modulo nativo Kotlin `CallScreeningService` + ruolo `ROLE_CALL_SCREENING`, Android 10+; UI Flutter via platform channel; persistenza solo on-device). Traduce CG-SDS-001 in una lista eseguibile che fa rispettare le regole di Clean / Hexagonal Architecture per tutta la fase di implementazione.

**Utente concreto e beneficio misurabile (tracer-bullet):** il proprietario del dispositivo (UN-01…UN-06) ottiene, nella prima fetta verticale (TASK-03→04→09→10→11→17→19→21→22), il loop completo *chiamata sconosciuta → rifiuto senza squillo → 1 SMS automatico → riga in cronologia* verificabile su device con 2 SIM di laboratorio. Le fette successive aggiungono triage/classificazione rapida (UN-03, <30 s mediana, TP-1103), gestione liste/profili (UN-05) e hardening release (zero PII nei log, zero-egress, declaration Play).

**In scope (RF-1…RF-10):** intercettazione pre-squillo (RF-1), rifiuto visibile-non-rubrica-non-whitelist (RF-2/RF-5), record per rifiuto (RF-3), 1 solo SMS automatico con testo configurabile e default fissato (RF-4/RF-9), blacklist sempre rifiutata con toggle SMS default OFF (RF-6), triage SMS all'apertura con 2 CTA (RF-7), CRUD liste + profilo numero (RF-8), effetto immediato delle decisioni (RF-10).

**Fuori perimetro:** iOS, Android <10 (solo messaggio di incompatibilità), cloud/backend/sync, chiamate in uscita, spam-database esterne, ML scoring.

**Governing implementation rules:**
- **Nessun codice per un task finché tutti i suoi `Depends On` sono completi e revisionati.**
- **Ogni task produce esattamente un'unità di implementazione e il suo file di test.**
- **Il Domain deve compilare e tutti i suoi unit test devono passare prima che inizi qualsiasi task Application.**
- **L'Application deve compilare e tutti i suoi test devono passare prima che inizi qualsiasi task Infrastructure.**
- **Nessun task può introdurre un import che violi la direzione delle dipendenze (Domain ← Application ← Infrastructure).** Il modulo `:domain` puro Kotlin ha zero import `android.*`, `androidx.*`, `io.flutter.*`; l'Application non importa Room/`SmsManager`/Flutter; l'Infrastructure non incorpora policy decisionale (vive in §8 SDS).
- **Regola idempotenza/costi:** un solo invio automatico per `event_id`; nessun auto-retry in background; un solo retry manuale (SRS-902). Qualsiasi violazione è un difetto bloccante.
- **Regola privacy:** nessun numero completo / corpo SMS / nome contatto nei log; solo hash o prefissi troncati (SRS-1003). Il gate TP-1003 è rosso se un solo numero-canarino appare in chiaro.

---

## 2. Execution Protocol

1. **Start** — Un engineer prende un task e lo porta a `in_progress`. Nessun task parallelo sullo stesso stream (screening-path vs UI possono procedere in parallelo solo se su stream diversi e senza dipendenze condivise).
2. **Implement** — Scrive i file indicati in `Source Files`.
3. **Test** — Scrive il test e conferma che tutti i TP mappati passano.
4. **Lint** — `detekt` + `flutter analyze` + forbidden-import check (`android.*` sotto `domain/` o `application/` = build rosso) a zero errori; `kotlinc` strict null (no `!!` in Domain/Application).
5. **Review** — Peer review contro la sezione SDS referenziata + controllo PII (grep canarino).
6. **Close** — Marca `done`. Il task successivo può partire.

**Gate di layer:** Phase 1 tutta verde → sblocca Phase 2. Phase 2 tutta verde → sblocca Phase 3. Phase 4 richiede Phase 3 verde + i 5 gate di release verdi (TP-301/TP-1202, TP-1003, TP-1201, TP-1203, TP-1101).

**Stime:** obbligatorie, in ore ideali + tag S (≤4h) / M (1g ≈ 8h) / L (2g ≈ 16h). Totale backlog: **≈ 196h (≈ 24.5 g-uomo)** esclusi device-test manuali E2E su carrier reale.

---

## 3. Project Directory Structure

Struttura canonica. Tutti i path dei task sono relativi a questa. Creata in Phase 0 prima di qualsiasi implementazione. Niente server, niente DAS/MongoDB, niente HTTP.

```
call-guard/
├── android/
│   ├── settings.gradle / build.gradle (AGP pinnato, minSdk 29)
│   ├── domain/                          # modulo Kotlin PURO (zero android.*)
│   │   └── src/main/kotlin/guard/domain/
│   │       ├── PhoneNumber.kt           # SU-DOM-01-01
│   │       ├── ScreeningDecision.kt     # SU-DOM-02-01
│   │       ├── SmsEligibility.kt        # SU-DOM-02-02
│   │       ├── CallRecord.kt            # SU-DOM-03-01
│   │       ├── TrustedEntry.kt          # SU-DOM-03-02
│   │       └── AutoReplyTemplate.kt     # SU-DOM-04-01 (+ DEFAULT_TEMPLATE)
│   ├── app/src/main/kotlin/guard/
│   │   ├── application/                 # use-case, solo porte
│   │   │   ├── ScreenIncomingCallUseCase.kt      # SU-APP-01-01
│   │   │   ├── RecordRejectedCallUseCase.kt      # SU-APP-02-01
│   │   │   ├── SendAutoReplyUseCase.kt           # SU-APP-03-01
│   │   │   ├── TriageInboundSmsUseCase.kt        # SU-APP-04-01
│   │   │   ├── ClassifyNumberUseCase.kt          # SU-APP-05-01
│   │   │   ├── ManageListsUseCase.kt             # SU-APP-06-01
│   │   │   ├── ConfigureSmsTemplateUseCase.kt    # SU-APP-07-01
│   │   │   └── ProtectionStatusUseCase.kt        # SU-APP-08-01
│   │   ├── infrastructure/              # adapter, unico implementatore per porta
│   │   │   ├── CallScreeningAdapter.kt  # SU-INF-01-01
│   │   │   ├── ContactsLookupAdapter.kt # SU-INF-02-01
│   │   │   ├── SmsSenderAdapter.kt      # SU-INF-03-01
│   │   │   ├── SmsInboxReaderAdapter.kt # SU-INF-04-01
│   │   │   ├── LocalStoreAdapter.kt     # SU-INF-05-01 (+ DAO, entities, prefs)
│   │   │   ├── PlatformChannelBridge.kt # SU-INF-06-01 (call_guard/bridge_v1)
│   │   │   └── DiagnosticsLogger.kt     # SU-INF-08-01 (scrub obbligatorio)
│   │   └── res/ + AndroidManifest.xml   # permessi minimi, allowBackup=false
├── lib/                                 # Flutter, solo presentazione
│   ├── main.dart
│   ├── bridge/channel_client.dart       # client cg/v1/* (SU-INF-06-01 lato Dart)
│   └── ui/                              # SU-INF-07-01: 6 superfici
│       ├── protection_onboarding.dart
│       ├── blocked_history.dart
│       ├── sms_triage.dart
│       ├── lists_whitelist.dart / lists_blacklist.dart
│       ├── number_profile.dart
│       └── sms_template_editor.dart
├── test/
│   ├── unit/domain/ + unit/application/ # JUnit5+MockK, flutter test (pura)
│   └── integration/                    # Robolectric, Room in-memory, Fake*
├── schemas/call_guard.db.v1.json       # Room exportSchema (baseline migrazioni)
└── detekt.yml / analysis_options.yaml
```

---

## 4. Phase 0 — Project Scaffold & Tooling

### TASK-01 — Scaffold repo, toolchain e gate di layer

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 0 — Scaffold |
| **Depends On** | None |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §2 (convenzioni, nullability, import ban), §3.5 (exportSchema), §11 (costanti build) |
| **SRS Trace** | SRS-201, SRS-1005 (minSdk 29, modulo nativo unico decisore) |
| **TP Trace** | TP-201 (ispezione statica: nessun telecom in Dart) |

**Source Files:**
- `android/settings.gradle`, `android/build.gradle`, `android/domain/build.gradle`
- `detekt.yml`, `lib/analysis_options.yaml`
- `schemas/.gitkeep` (baseline; il JSON v1 arriva con TASK-21)
- `test/unit/domain/ScaffoldGateTest.kt` (asserisce: modulo domain compila senza `android.*`)

**Implementation Notes:**
- `minSdk 29`, `target/compileSdk` pinnati e registrati; Flutter stable pinnato al build.
- Modulo `:domain` Kotlin puro; forbidden-import check che fallisce il build su `android.*|androidx.*|io.flutter.*` sotto `domain/` e `application/`. Divieto `!!` in Domain/Application (Detekt custom rule o code-review checklist vincolante).
- Path alias/codec: prefisso channel `cg/v1/` riservato; `call_guard/bridge_v1` fissato.

**Acceptance Criteria:**
- [ ] `domain` compila senza import Android/Flutter; check dedicato verde.
- [ ] `flutter analyze` e `detekt` a zero errori su scaffold vuoto.
- [ ] TP-201(a) verde: zero riferimenti `telecom`/`CallScreeningService` in `lib/`.

**Definition of Done:**
- [ ] Source compila con zero errori
- [ ] TP-201(a) passa
- [ ] Linter a zero errori
- [ ] Peer review approvata

### TASK-02 — Store skeleton, prefs seed contract e CI PII-gate

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 0 — Scaffold |
| **Depends On** | TASK-01 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §3 (tabelle `rejected_calls`, `trusted_entries`, `sms_triage`), §3.4 (chiavi `cg_sms_template_text`, `cg_blacklist_sms_enabled`), §10.8 (scrub) |
| **SRS Trace** | SRS-101, SRS-103, SRS-1002, SRS-1003 |
| **TP Trace** | TP-1002 (checklist manifest), TP-1003 (grep canarino, per ora su scaffold) |

**Source Files:**
- `android/app/src/main/kotlin/guard/infrastructure/LocalStoreAdapter.kt` (skeleton: nomi DB `call_guard.db` v1, `allowBackup=false`, transazioni `IMMEDIATE` — corpo completo in TASK-21)
- `android/app/src/main/AndroidManifest.xml` (permessi minimi dichiarati, nessun provider esportato, nessun `INTERNET` senza giustificazione → fail se presente)
- `test/integration/ScaffoldPrivacyGateTest.kt`

**Implementation Notes:**
- Fissa una volta qui: nomi tabelle/colonne snake_case, chiavi prefs `cg_*`, default template carattere-esatto (SDS §8.6), flag default `false`. TASK successivi non possono rinominare senza Change Request.
- CI: step `pii-grep` che fallisce su pattern E.164-canarino nei log di test; step `egress-check` (proxy/emulatore) predisposto per Phase 4.

**Acceptance Criteria:**
- [ ] Manifest senza `INTERNET`, senza provider esportati, `allowBackup=false`.
- [ ] Chiavi prefs e nomi DB/tabelle presenti come costanti; default template identico al §8.6 carattere-per-carattere.
- [ ] Job CI `pii-grep` verde su run vuoto.

**Definition of Done:**
- [ ] Source compila con zero errori
- [ ] TP-1002 checklist manifest verde; TP-1003 gate attivo
- [ ] Linter a zero errori
- [ ] Peer review approvata

---

## 5. Phase 1 — Domain Layer

Solo funzioni pure ed entità. Nessun I/O. Orologio solo via `IClock` iniettato. Inizio dopo TASK-02 verde.

### TASK-03 — PhoneNumber: normalizzazione, visibilità, dialabilità

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 1 — Domain Layer |
| **Depends On** | TASK-02 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §8.1 — SU-DOM-01-01 (algoritmo 8 passi, equivalenza `+39`/`0039`/`0`, short-code ≤6) |
| **SRS Trace** | SRS-302, SRS-304, SRS-305 |
| **TP Trace** | TP-302 (matrice), TP-304, TP-305, TP-701 (collasso `+39 3330000099` = `333 000 0099`) |

**Source Files:**
- `android/domain/src/main/kotlin/guard/domain/PhoneNumber.kt`
- `test/unit/domain/PhoneNumberTest.kt`

**Implementation Notes:**
- Mai throw sullo screening path: input non parsabile → `dialableForSms=false` / `Hidden` / `Empty`. Pattern lineari, nessun `toLowerCase` locale-dipendente sui numeri.
- Fixture normative: `40400` non componibile, `BANCA` alfa non componibile, `PRESENTATION_RESTRICTED/UNKNOWN` → `Hidden`.

**Acceptance Criteria:**
- [ ] 5 input TP-305 classificati correttamente; solo `+393330000030` componibile.
- [ ] Hidden/vuoto mai componibili; equivalenti nazionali collassano (TP-701).

**Definition of Done:**
- [ ] Source compila; zero import infrastructure
- [ ] Tutti i TP mappati passano
- [ ] Linter zero errori; review vs SDS §8.1

### TASK-04 — ScreeningDecision: precedenza pura

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 1 — Domain Layer |
| **Depends On** | TASK-03 |
| **Estimate** | S (4h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §8.1 — SU-DOM-02-01 (ordine normativo: no-role → anonimo-pass → blacklist → contacts/whitelist-pass → unknown-reject; mai `SILENCE_FALLBACK` qui) |
| **SRS Trace** | SRS-302, SRS-303, SRS-304, SRS-306, SRS-703 |
| **TP Trace** | TP-302, TP-303, TP-304, TP-306, TP-703 (6 combo) |

**Source Files:**
- `android/domain/src/main/kotlin/guard/domain/ScreeningDecision.kt`
- `test/unit/domain/ScreeningDecisionTest.kt`

**Implementation Notes:**
- Funzione totale: tutte le 32 combo definite dall'ordine; `roleHeld=false` → sempre PASS (fail-open). Nessuna conoscenza SMS.

**Acceptance Criteria:**
- [ ] 10/10 combo TP-302 conformi; nessun rifiuto senza ruolo.
- [ ] 6/6 combo TP-703 conformi (blacklist prevale anche su rubrica+whitelist).

**Definition of Done:**
- [ ] Source compila; zero import infrastructure
- [ ] Tutti i TP mappati passano
- [ ] Linter zero errori; review vs SDS §8.1

### TASK-05 — SmsEligibility: gate puro dell'invio

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 1 — Domain Layer |
| **Depends On** | TASK-03 |
| **Estimate** | S (4h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §8.1 — SU-DOM-02-02 (Hidden → NON_DIALABLE → BLACKLISTED → Eligible; nuovi skip = riga registry + enum ledger + TP) |
| **SRS Trace** | SRS-103, SRS-304, SRS-305, SRS-501, SRS-502 |
| **TP Trace** | TP-305, TP-502 |

**Source Files:**
- `android/domain/src/main/kotlin/guard/domain/SmsEligibility.kt`
- `test/unit/domain/SmsEligibilityTest.kt`

**Implementation Notes:**
- Valutata prima di ogni chiamata `SmsManager` senza eccezioni. Default flag OFF → blacklist skippata.

**Acceptance Criteria:**
- [ ] Blacklist + flag OFF → `Skipped(BLACKLISTED)`; flag ON → `Eligible`.
- [ ] Hidden/vuoto → `HIDDEN`; short-code/alfa → `NON_DIALABLE`.

**Definition of Done:**
- [ ] Source compila; zero import infrastructure
- [ ] Tutti i TP mappati passano
- [ ] Linter zero errori; review vs SDS §8.1

### TASK-06 — CallRecord: entità + macchina ledger SMS

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 1 — Domain Layer |
| **Depends On** | TASK-04, TASK-05 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §8.2 — SU-DOM-03-01 (`pending → sent|failed|skipped`; `failed → sent|failed` una sola volta; `sent`/`skipped` terminali; `retry_count` 0→1; mai corpo SMS, solo `template_ref` hash) |
| **SRS Trace** | SRS-401, SRS-402 |
| **TP Trace** | TP-401 (mai aggregati), TP-402, TP-501 (idempotenza per `event_id`) |

**Source Files:**
- `android/domain/src/main/kotlin/guard/domain/CallRecord.kt`
- `test/unit/domain/CallRecordTest.kt`

**Implementation Notes:**
- `create` rifiuta verdict PASS (contatti/anonimi mai loggati). Due chiamate stesso numero/minuto = due record. `event_id` UUIDv4 unico punto di generazione (Application, ma invariante definita qui).

**Acceptance Criteria:**
- [ ] Transizioni terminali rifiutate (`sent`/`skipped` immutabili); retry oltre 1 rifiutato.
- [ ] Nessun campo corpo SMS nell'entità; solo `template_ref`.

**Definition of Done:**
- [ ] Source compila; zero import infrastructure
- [ ] Tutti i TP mappati passano
- [ ] Linter zero errori; review vs SDS §8.2

### TASK-07 — TrustedEntry: mutua esclusione e move

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 1 — Domain Layer |
| **Depends On** | TASK-03 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §8.2 — SU-DOM-03-02 (`UNIQUE(normalized_number)` cross-lista; move con `confirmedMove`; `remove` mai cancella history; `category` free-text v1) |
| **SRS Trace** | SRS-603, SRS-604, SRS-701, SRS-702, SRS-802 |
| **TP Trace** | TP-603, TP-604, TP-701, TP-702 |

**Source Files:**
- `android/domain/src/main/kotlin/guard/domain/TrustedEntry.kt`
- `test/unit/domain/TrustedEntryTest.kt`

**Implementation Notes:**
- Numero non normalizzabile → `DomainError(VALIDATION_INVALID_NUMBER)`. Stessa lista → `edit`, mai duplicato. Move preserva `date_added_ms`, aggiorna `last_modified_ms` + `source`.

**Acceptance Criteria:**
- [ ] Mai doppia appartenenza; move senza conferma esplicita rifiutato con `NEEDS_CONFIRM`.
- [ ] `remove` lascia la history intatta (asserito a livello domain come invariante documentata, verificato IT in TASK-21/22).

**Definition of Done:**
- [ ] Source compila; zero import infrastructure
- [ ] Tutti i TP mappati passano
- [ ] Linter zero errori; review vs SDS §8.2

### TASK-08 — AutoReplyTemplate: default, validazione, segmenti

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 1 — Domain Layer |
| **Depends On** | TASK-02 |
| **Estimate** | S (4h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §8.2 — SU-DOM-04-01 + §4.1 (costante `DEFAULT_TEMPLATE` unica; `max_chars=480`; GSM-7 vs UCS-2 per 3GPP 23.038; default = 1 segmento GSM-7) |
| **SRS Trace** | SRS-101, SRS-503 |
| **TP Trace** | TP-101 (default carattere-esatto + 1 segmento), TP-503, TP-1102(b/c) |

**Source Files:**
- `android/domain/src/main/kotlin/guard/domain/AutoReplyTemplate.kt`
- `test/unit/domain/AutoReplyTemplateTest.kt`

**Implementation Notes:**
- Vuoto/spazi → `VALIDATION_EMPTY_TEMPLATE`; oltre 480 → `VALIDATION_TEMPLATE_TOO_LONG`. Save rifiutato = valore precedente intatto (enforcato in Application, invariante definita qui).

**Acceptance Criteria:**
- [ ] Default esatto + 1 segmento GSM-7 dimostrato in test.
- [ ] Vuoto/spazi/oltre-limite rifiutati; conteggio segmenti corretto GSM-7 e UCS-2.

**Definition of Done:**
- [ ] Source compila; zero import infrastructure
- [ ] Tutti i TP mappati passano
- [ ] Linter zero errori; review vs SDS §8.2

**Gate:** Tutte TASK-03…TASK-08 verdi → sblocca Phase 2.

---

## 6. Phase 2 — Application Layer

Solo dopo Phase 1 verde. Solo porte, mai infrastruttura diretta. Regola screening-path (binding): nessuna rete, nessuna scrittura Room, nessun invio SMS prima di aver restituito la decisione.

### TASK-09 — ScreenIncomingCallUseCase (orchestratore time-critical)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 2 — Application Layer |
| **Depends On** | TASK-04 (Phase 1 completa di fatto: TASK-03…08) |
| **Estimate** | L (16h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §9.1 — SU-APP-01-01 (snapshot solo in memoria, cache contesto ≤5 s, enqueue off-path con dedup per `callId` telecom, diagnostica scrubbed) |
| **SRS Trace** | SRS-201, SRS-301, SRS-302, SRS-303, SRS-306, SRS-703, SRS-1001, SRS-1004 |
| **TP Trace** | TP-201(b) (decide senza Flutter), TP-301 (p99 <500 ms, zero rete), TP-1001, TP-1004 |

**Source Files:**
- `android/app/src/main/kotlin/guard/application/ScreenIncomingCallUseCase.kt`
- `test/unit/application/ScreenIncomingCallUseCaseTest.kt`

**Implementation Notes:**
- Eccezione in steps 1–4 → PASS fail-open + `INTERNAL_ERROR` scrubbed. Timeout → PASS + contatore `SCREENING_TIMEOUT`, evento NON registrato come app-rejected. Diagnostica solo `{screening_event_id, verdict_origin, elapsed_ms}`.

**Acceptance Criteria:**
- [ ] Decide senza Flutter attivo (TP-201b) usando solo snapshot.
- [ ] 20/20 decisioni entro timeout con 10k contatti + 1k liste sintetiche; zero accessi rete osservati (TP-301/TP-1001).

**Definition of Done:**
- [ ] Compila; solo porte (`IProtectionStateProvider`, `IDecisionSnapshotProvider`, `IDiagnostics`), nessun import Room/SmsManager/Flutter
- [ ] TP mappati passano; review vs SDS §9.1

### TASK-10 — RecordRejectedCallUseCase (un record per rifiuto)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 2 — Application Layer |
| **Depends On** | TASK-09 |
| **Estimate** | S (4h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §9.1 — SU-APP-02-01 (verdict PASS → rifiuto silenzioso; insert transazionale; `STORE_UNWRITABLE` → retry al prossimo open, mai drop silenzioso) |
| **SRS Trace** | SRS-401, SRS-402 |
| **TP Trace** | TP-303 (contatti: zero righe), TP-304 (anonimi: zero righe), TP-401, TP-402 |

**Source Files:**
- `android/app/src/main/kotlin/guard/application/RecordRejectedCallUseCase.kt`
- `test/unit/application/RecordRejectedCallUseCaseTest.kt`

**Implementation Notes:**
- Inoltra `event_id` a SendAutoReply senza attenderlo. Timestamp da `IClock` (orologio fake nei test per ordinamento T1<T2<T3).

**Acceptance Criteria:**
- [ ] Contatti/anonimi non creano righe; 2 rifiuti stesso numero = 2 righe con tutti i campi (TP-401).
- [ ] Scrittura fallita → `STORE_UNWRITABLE` + retry schedulato, mai mezza riga.

**Definition of Done:**
- [ ] Compila; solo porte; TP mappati passano; review vs SDS §9.1

### TASK-11 — SendAutoReplyUseCase (esattamente-uno + 1 retry manuale)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 2 — Application Layer |
| **Depends On** | TASK-10 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §9.1 — SU-APP-03-01 (check `sms_status!=pending` → `SMS_DUPLICATE_SUPPRESSED`; skip-policy senza chiamare il sender; template persistito mai costante diretta; retry rifiutato se `sent`/`retry_count==1`/`skipped`) |
| **SRS Trace** | SRS-103, SRS-501, SRS-502, SRS-902 |
| **TP Trace** | TP-402, TP-501, TP-502, TP-902, TP-1102(a) |

**Source Files:**
- `android/app/src/main/kotlin/guard/application/SendAutoReplyUseCase.kt`
- `test/unit/application/SendAutoReplyUseCaseTest.kt`

**Implementation Notes:**
- Un solo tentativo automatico, nessun auto-retry. `template_ref = SHA-256 hex primi 16` del testo usato. Nessun send background senza tap utente.

**Acceptance Criteria:**
- [ ] Doppio evento stesso `event_id` → 1 solo invio (TP-501).
- [ ] Flag OFF + blacklist → `skipped/blacklisted`, zero chiamate sender (TP-502); retry oltre 1 o su `sent` rifiutato (TP-902).

**Definition of Done:**
- [ ] Compila; solo porte; TP mappati passano; review vs SDS §9.1

### TASK-12 — TriageInboundSmsUseCase (foreground, linked, pending-first)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 2 — Application Layer |
| **Depends On** | TASK-10 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §9.1 — SU-APP-04-01 (foreground-only, `date >= watermark`, cap 200 newest-first, dedup `provider_msg_id`, `pending|classified|unlinked`) |
| **SRS Trace** | SRS-601 |
| **TP Trace** | TP-601, TP-1104 |

**Source Files:**
- `android/app/src/main/kotlin/guard/application/TriageInboundSmsUseCase.kt`
- `test/unit/application/TriageInboundSmsUseCaseTest.kt`

**Implementation Notes:**
- Senza permesso SMS-read → `{SMS_ACCESS_MISSING}` + guida, zero letture. Mittente non normalizzabile → `unlinked`, nessuna CTA distruttiva.

**Acceptance Criteria:**
- [ ] Solo A (rifiutato, non classificato) in coda pending con `linked_event_id`; B mai-rifiutato = `unlinked`; C in lista = escluso (TP-601).
- [ ] Cap 200 + watermark: nessuna lettura full-backup.

**Definition of Done:**
- [ ] Compila; solo porte; TP mappati passano; review vs SDS §9.1

### TASK-13 — ClassifyNumberUseCase (commit sincrono, effetto immediato)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 2 — Application Layer |
| **Depends On** | TASK-12 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §9.2 — SU-APP-05-01 (transazione unica: upsert lista + clear pending + rebuild snapshot prima del return; `effect` statement; `NEEDS_CONFIRM` senza `confirmedMove`) |
| **SRS Trace** | SRS-307, SRS-603, SRS-604, SRS-704 |
| **TP Trace** | TP-307 (reject→pass→reject senza restart), TP-603, TP-604, TP-704 |

**Source Files:**
- `android/app/src/main/kotlin/guard/application/ClassifyNumberUseCase.kt`
- `test/unit/application/ClassifyNumberUseCaseTest.kt`

**Implementation Notes:**
- `source = sms_classification | call_history`. Nessuna UI ottimistica che preceda il commit.

**Acceptance Criteria:**
- [ ] Classifica → richiamata dallo stesso numero usa il nuovo verdetto senza restart (TP-307/603/604).
- [ ] Numero nell'altra lista senza conferma → `NEEDS_CONFIRM`, nessuna scrittura parziale.

**Definition of Done:**
- [ ] Compila; solo porte; TP mappati passano; review vs SDS §9.2

### TASK-14 — ManageListsUseCase (CRUD/move/edit profili)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 2 — Application Layer |
| **Depends On** | TASK-13 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §9.2 — SU-APP-06-01 (`source=manual`; `remove` mai tocca history; `edit` solo nome/note/categoria, numero immutabile) |
| **SRS Trace** | SRS-307, SRS-701, SRS-702 |
| **TP Trace** | TP-701, TP-702 |

**Source Files:**
- `android/app/src/main/kotlin/guard/application/ManageListsUseCase.kt`
- `test/unit/application/ManageListsUseCaseTest.kt`

**Implementation Notes:**
- Stesso core transazionale di TASK-13 + rebuild snapshot sincrono a ogni mutazione con effect statement.

**Acceptance Criteria:**
- [ ] CRUD completi; formati equivalenti collassano in un'unica entry (TP-701).
- [ ] Mai doppia appartenenza; move registrato con timestamp+source (TP-702).

**Definition of Done:**
- [ ] Compila; solo porte; TP mappati passano; review vs SDS §9.2

### TASK-15 — ConfigureSmsTemplateUseCase (get/set/restore)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 2 — Application Layer |
| **Depends On** | TASK-08 |
| **Estimate** | S (4h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §9.2 — SU-APP-07-01 (set valida → persiste o mantiene precedente; restore-default; prossimo invio usa il nuovo testo) |
| **SRS Trace** | SRS-101, SRS-102, SRS-503 |
| **TP Trace** | TP-101, TP-102, TP-503 |

**Source Files:**
- `android/app/src/main/kotlin/guard/application/ConfigureSmsTemplateUseCase.kt`
- `test/unit/application/ConfigureSmsTemplateUseCaseTest.kt`

**Implementation Notes:**
- Legge/scrive solo via `ITemplateStore` (mai la costante direttamente nel path di invio — SRS-102).

**Acceptance Criteria:**
- [ ] Valido salvato e usato dall'invio successivo dopo kill/riavvio (TP-102).
- [ ] Vuoto/oltre-limite rifiutati con field error, precedente intatto (TP-503).

**Definition of Done:**
- [ ] Compila; solo porte; TP mappati passano; review vs SDS §9.2

### TASK-16 — ProtectionStatusUseCase (ruolo + permessi + OS)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 2 — Application Layer |
| **Depends On** | TASK-09 |
| **Estimate** | S (4h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §9.2 — SU-APP-08-01 (`protectionActive = osSupported && hasRole`; `degraded` se bit SMS/contatti negati; deep-link, mai claim di protezione inattiva) |
| **SRS Trace** | SRS-202, SRS-203, SRS-1004, SRS-1005 |
| **TP Trace** | TP-202, TP-203, TP-1005, TP-1004 |

**Source Files:**
- `android/app/src/main/kotlin/guard/application/ProtectionStatusUseCase.kt`
- `test/unit/application/ProtectionStatusUseCaseTest.kt`

**Implementation Notes:**
- Query live a ogni resume, cache mai oltre il resume. API <29 → `OS_UNSUPPORTED`, protezione sempre off.

**Acceptance Criteria:**
- [ ] Ruolo mancante → stato bloccante + singola azione verso system request; chiamate passano (TP-202).
- [ ] Ogni permesso negato → messaggio dedicato con azione (TP-203); API 28 → incompatibilità esplicita, nessun crash (TP-1005).

**Definition of Done:**
- [ ] Compila; solo porte; TP mappati passano; review vs SDS §9.2

**Gate:** Tutte TASK-09…TASK-16 verdi → sblocca Phase 3.

---

## 7. Phase 3 — Infrastructure Layer

Solo dopo Phase 2 verde. Ogni adapter implementa esattamente una porta; mai policy decisionale duplicata.

### TASK-17 — CallScreeningAdapter (`onScreenCall`, attuazione, timeout-safe)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 3 — Infrastructure Layer |
| **Depends On** | TASK-09 |
| **Estimate** | L (16h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §10.1 — SU-INF-01-01 (lettura snapshot, `CallResponse disallow/silence`, fallback `silence_fallback` con ledger onesto AD-05, diagnostica senza PII) |
| **SRS Trace** | SRS-201, SRS-301, SRS-302, SRS-306, SRS-307 |
| **TP Trace** | TP-301, TP-302, TP-1202 (OEM aggressivo, revoca a caldo) |

**Source Files:**
- `android/app/src/main/kotlin/guard/infrastructure/CallScreeningAdapter.kt`
- `test/integration/CallScreeningAdapterTest.kt` (Robolectric + `FakeCallScreeningCall`)

**Implementation Notes:**
- Decide e risponde prima di qualsiasi Room/SMS. Registra quale attuazione è stata usata (`disconnect|silence_fallback|none_role_missing`). AD-05: tenta disconnect standard, fallback silenzio definito, entrambi deterministici e testati sulla matrice OEM.

**Acceptance Criteria:**
- [ ] Sconosciuto → `disallow=true` senza squillo; contatti/whitelist/anonimi → pass; blacklist → reject con origine blacklist.
- [ ] Revoca ruolo a caldo → fail-open (squilla) + banner alla riapertura, nessuno stallo (TP-1202).

**Definition of Done:**
- [ ] Compila; error mapping vs registry §7; TP mappati passano; review vs SDS §10.1

### TASK-18 — ContactsLookupAdapter (read-only + snapshot builder)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 3 — Infrastructure Layer |
| **Depends On** | TASK-17 |
| **Estimate** | S (4h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §10.2 — SU-INF-02-01 (`PhoneLookup` solo presenza, nessun contenuto copiato oltre lo snapshot; negato → feature-gate) |
| **SRS Trace** | SRS-203, SRS-302, SRS-303 |
| **TP Trace** | TP-203(a), TP-303, TP-1101 |

**Source Files:**
- `android/app/src/main/kotlin/guard/infrastructure/ContactsLookupAdapter.kt`
- `test/integration/ContactsLookupAdapterTest.kt` (`FakeContactsProvider`)

**Implementation Notes:**
- Contenuti rubrica mai copiati (solo booleano presenza in snapshot). Equivalenza numeri identica a TASK-03.

**Acceptance Criteria:**
- [ ] Senza `READ_CONTACTS` → confronto disattivato con messaggio, nessuna eccezione (TP-203a).
- [ ] Contatto noto → passa senza righe/SMS (TP-303).

**Definition of Done:**
- [ ] Compila; TP mappati passano; review vs SDS §10.2

### TASK-19 — SmsSenderAdapter (`SmsManager` + mapping esiti)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 3 — Infrastructure Layer |
| **Depends On** | TASK-11 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §10.3 — SU-INF-03-01 (guard dialabilità/short-code prima del sender; idempotency-key carrier; `NO_SERVICE`/`NULL_PDU`/radio → `failed+reason`) |
| **SRS Trace** | SRS-203, SRS-305, SRS-501 |
| **TP Trace** | TP-305, TP-402, TP-501, TP-902 |

**Source Files:**
- `android/app/src/main/kotlin/guard/infrastructure/SmsSenderAdapter.kt`
- `test/integration/SmsSenderAdapterTest.kt` (`FakeSmsManager`: success / NO_SERVICE / NULL_PDU)

**Implementation Notes:**
- Mai chiamato per skip-policy (TASK-11 lo impedisce); qui doppia guardia difensiva + mapping. Nessun secondo tentativo automatico a questo livello.

**Acceptance Criteria:**
- [ ] Success → `sent + sent_at + template_ref`; NO_SERVICE/NULL_PDU → `failed+reason` con 1 solo retry manuale possibile.
- [ ] Zero invii verso short-code/alfa/non componibili anche se chiamati per errore.

**Definition of Done:**
- [ ] Compila; TP mappati passano; review vs SDS §10.3

### TASK-20 — SmsInboxReaderAdapter (foreground, scoped, watermark)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 3 — Infrastructure Layer |
| **Depends On** | TASK-12 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §10.4 — SU-INF-04-01 (query inbox foreground `date >= watermark` cap 200; scope minimo AD-03; negato → guida; mai background listener senza CR che rivaluti RSK-105) |
| **SRS Trace** | SRS-203, SRS-601 |
| **TP Trace** | TP-203(c), TP-601, TP-1104 |

**Source Files:**
- `android/app/src/main/kotlin/guard/infrastructure/SmsInboxReaderAdapter.kt`
- `test/integration/SmsInboxReaderAdapterTest.kt`

**Implementation Notes:**
- AD-03 deve essere chiuso prima del sign-off SDS: scope minimo che soddisfa il triage foreground; alternativa Consent/Retriever valutata e documentata (input al gate TP-1203).

**Acceptance Criteria:**
- [ ] Senza permesso → vista `accesso SMS mancante`, zero letture (TP-203c).
- [ ] Watermark + cap rispettati; dedup `provider_msg_id`; corpi solo in storage app-privato, mai nei log.

**Definition of Done:**
- [ ] Compila; TP mappati passano; review vs SDS §10.4 (+ evidenza AD-03)

### TASK-21 — LocalStoreAdapter (Room + prefs + migrazioni + snapshot sync)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 3 — Infrastructure Layer |
| **Depends On** | TASK-10, TASK-13, TASK-14, TASK-15 |
| **Estimate** | L (16h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §10.5 — SU-INF-05-01 (SQL normativo §3.1–3.3, CHECK, indici; seed transazionale prefs §3.4; rebuild snapshot sincrono nella stessa transazione; `Migration` v1→v2 con test) |
| **SRS Trace** | SRS-101, SRS-102, SRS-103, SRS-307, SRS-401, SRS-402, SRS-403, SRS-502, SRS-603, SRS-604, SRS-701, SRS-705 |
| **TP Trace** | TP-101, TP-102, TP-103, TP-307, TP-401, TP-402, TP-403, TP-502, TP-701, TP-702, TP-705, TP-1201 |

**Source Files:**
- `android/app/src/main/kotlin/guard/infrastructure/LocalStoreAdapter.kt` (+ `entities/`, `dao/`, `prefs/`)
- `schemas/call_guard.db.v1.json` (exportSchema, baseline)
- `test/integration/LocalStoreAdapterTest.kt` (Room in-memory + su-disco per reboot, fault-injection kill-durante-scrittura)

**Implementation Notes:**
- Vincoli CHECK (`retry_count 0..1`, `outcome='rejected'`, enum status) + UNIQUE (`event_id`, `normalized_number` cross-lista, `provider_msg_id`) enforced a DB, non solo a codice. `remove` liste mai cancella history. Kill durante scrittura → rollback, mai mezza riga.

**Acceptance Criteria:**
- [ ] Dataset completo sopravvive a kill/reboot/upgrade senza perdite; scrittura interrotta = rollback (TP-1201/403/705).
- [ ] Ogni commit liste rebuilda lo snapshot prima del return (TP-307 dimostrato a livello store).
- [ ] Seed primo avvio: template default + flag OFF presenti prima di qualsiasi send (TP-101/103).

**Definition of Done:**
- [ ] Compila; schema JSON committato; TP mappati passano; review vs SDS §3 + §10.5

### TASK-22 — PlatformChannelBridge (`call_guard/bridge_v1`, codec, errori)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 3 — Infrastructure Layer |
| **Depends On** | TASK-13, TASK-14, TASK-15, TASK-16, TASK-21 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §6 + §10.6 — SU-INF-06-01 (15 metodi `cg/v1/*`, tipi wire `BlockedRow/TriageItem/TrustedEntryWire/ProtectionStatus`, envelope `{code,message,action}`, timestamp ISO-8601, numeri canonici) |
| **SRS Trace** | SRS-307, SRS-603, SRS-604, SRS-902 (immediatezza sincrona) + tutti i flussi channel |
| **TP Trace** | TP-307, TP-603, TP-604, TP-704, TP-902 |

**Source Files:**
- `android/app/src/main/kotlin/guard/infrastructure/PlatformChannelBridge.kt`
- `lib/bridge/channel_client.dart`
- `test/integration/PlatformChannelBridgeTest.kt`

**Implementation Notes:**
- `classifyNumber`/`manageList` ritornano solo dopo commit Room + rebuild snapshot (SRS-307). Valori enum futuri ignoti → fallback `unknown` → `INTERNAL_ERROR`. PII su channel mai loggata su entrambi i lati.

**Acceptance Criteria:**
- [ ] Tutti i 15 metodi con codec esatto §6.2/§6.3; timestamp ISO-8601; errori solo con codici §7.
- [ ] Dart non re-implementa normalizzazione/precedenza/eligibility (TP-201 runtime).

**Definition of Done:**
- [ ] Compila (Kotlin + Dart); TP mappati passano; review vs SDS §6 + §10.6

### TASK-23 — FlutterPresentation (6 superfici + filtri + CTA + undo)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 3 — Infrastructure Layer |
| **Depends On** | TASK-22 |
| **Estimate** | L (16h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §10.7 — SU-INF-07-01 (onboarding protezione, cronologia, triage con 2 CTA, whitelist, blacklist, editor template + dettaglio profilo; filtro sottostringa + sort disc; confirm+undo RSK-108; surfacing §7 senza PII/stack) |
| **SRS Trace** | SRS-103, SRS-202, SRS-203, SRS-503, SRS-602, SRS-701, SRS-704, SRS-801, SRS-802, SRS-901, SRS-902, SRS-1004, SRS-1005 |
| **TP Trace** | TP-202, TP-203, TP-503, TP-602, TP-704, TP-801, TP-802, TP-901, TP-1103, TP-1104 |

**Source Files:**
- `lib/ui/*.dart` (6 superfici + `number_profile.dart`, `sms_template_editor.dart`)
- `test/integration/FlutterPresentationTest.dart` (widget + Espresso per CTA/notifica/deep-link)

**Implementation Notes:**
- Label esatte: `Accetta (whitelist)` / `Rifiuta (blacklist)` sempre visibili senza menu (TP-602). Confirm su move cross-lista + undo immediato (RSK-108). Badge pending + notifica locale con deep-link al triage (RSK-109). Contatore segmenti GSM-7/UCS-2 nell'editor. Superfici errore con azione correttiva, mai stack trace.

**Acceptance Criteria:**
- [ ] 2 CTA esatte visibili senza navigazione annidata, con content-description (TP-602).
- [ ] 3 liste con filtro sottostringa + sort disc; troncamento numero vietato (TP-801); dettaglio profilo con storico + edit 3 campi persistiti dopo restart (TP-802).
- [ ] Triage mediano <30 s su 10 casi; ogni errore annullabile senza perdita history (TP-1103); notifica→triage deep-link diretto (TP-1104).

**Definition of Done:**
- [ ] `flutter analyze` zero errori; TP mappati passano; review vs SDS §10.7 + registry §7

### TASK-24 — DiagnosticsLogger (scrub PII obbligatorio + contatori)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 3 — Infrastructure Layer |
| **Depends On** | TASK-17, TASK-19 |
| **Estimate** | S (4h) |
| **IEC 62304 Phase** | 5.5 |
| **SDS Reference** | §10.8 — SU-INF-08-01 (`scrub()` con allowlist chiavi context; solo hash/prefissi; contatori screening OK/role-missing/timeout/SMS sent-failed-skipped senza identificatori) |
| **SRS Trace** | SRS-901, SRS-1002, SRS-1003 |
| **TP Trace** | TP-901, TP-1002, TP-1003 (gate bloccante) |

**Source Files:**
- `android/app/src/main/kotlin/guard/infrastructure/DiagnosticsLogger.kt`
- `test/integration/DiagnosticsLoggerTest.kt` (canarini: numeri/nomi/corpi → zero match in chiaro)

**Implementation Notes:**
- `DomainError.context` loggato solo dopo `scrub()`; chiavi non-allowlist droppate. Qualsiasi futuro crash-tool richiede scrubber + opt-in + CR (ARCH P-05).

**Acceptance Criteria:**
- [ ] Suite IT+E2E completa: zero PII in chiaro in logcat/file/crash (TP-1003 verde o release bloccata).
- [ ] Contatori operativi senza identificatori; superfici errore senza PII extra né stack (TP-901).

**Definition of Done:**
- [ ] Compila; TP mappati passano; review vs SDS §10.8

---

## 8. Phase 4 — Integration Testing & Coverage Closure

### TASK-25 — Fetta tracer-bullet E2E su device (rifiuto→SMS→cronologia→triage→classifica)

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 4 — Integration Testing |
| **Depends On** | TASK-17, TASK-19, TASK-20, TASK-21, TASK-22, TASK-23 |
| **Estimate** | L (16h) |
| **IEC 62304 Phase** | 5.6 |
| **SDS Reference** | §5–§7 (ProtectionContext), sequenze ARCH §7.1–7.3 |
| **SRS Trace** | Tutti RF-1…RF-10 (verifica verticale) |
| **TP Trace** | TP-1101 (10/10 squillo/reject), TP-1102 (1:1 eventi:invii, 1 segmento), TP-1104, TP-301, TP-1001 |

**Source Files:**
- `test/integration/TracerBulletE2ETest.kt` (`integration_test` + Espresso script)
- `docs/e2e-tracer-evidence.md` (run log con timestamp, device, API level — no PII)

**Implementation Notes:**
- Device fisici: 1 Pixel + 1 OEM battery-aggressivo; API 29–35; 2 SIM laboratorio; 10 chiamate controllo (5 note/whitelist squillano, 5 sconosciute mai squillo). Eseguire anche con rete disabilitata (5 run) + proxy capture (zero-egress). Nessun SMS a numerazioni reali di terzi. Dual-SIM best-effort per AMB-05.

**Acceptance Criteria:**
- [ ] 10/10 conformi (TP-1101); eventi:invii = 1:1; default 1 segmento; zero doppi invii (TP-1102).
- [ ] 20/20 decisioni entro timeout; zero pacchetti nel path (TP-301/TP-1001); notifica+ badge + deep-link triage funzionanti (TP-1104).

**Definition of Done:**
- [ ] Tutti i TP mappati passano su entrambi i device; evidence log senza PII; review TA+PM

### TASK-26 — Coverage closure, gate release e Test Execution Report

| Field | Value |
|---|---|
| **Status** | todo |
| **Phase** | 4 — Integration Testing |
| **Depends On** | Tutti TASK-01…TASK-25 |
| **Estimate** | M (8h) |
| **IEC 62304 Phase** | 5.6 |
| **SDS Reference** | — (chiusura su registry §7 e wire §6) |
| **SRS Trace** | Tutti SRS-101…SRS-1005 |
| **TP Trace** | Tutti TP-101…TP-1203 (nessun gap vs matrice TP §5–§6) |

**Source Files:**
- `test/integration/CoverageClosureTest.kt` (casi residui non coperti in Phase 1–3)
- `docs/test-execution-report.md` (bozza CG-TER-001: esiti, coverage, gate)

**Implementation Notes:**
- Coverage ≥80% linee/funzioni/statement/branch su tutti i layer (o eccezioni documentate approvate QA). Gate vincolanti verdi prima dell'approvazione: TP-1003, TP-301/TP-1202, TP-1201, TP-1203 (declaration Play + fallback solo-rifiuto senza SEND_SMS), TP-1101. Residui MEDIO RSK-101/105/109 accettati ALARP con KPI post-rilascio (reclami chiamata persa, esito declaration, mediana apertura post-rifiuto).

**Acceptance Criteria:**
- [ ] Tutti i TP-101…TP-1203 verdi; coverage ≥80% dimostrata dal report.
- [ ] Zero security-failure aperti; zero compliance-failure aperti; TER bozza prodotta.

**Definition of Done:**
- [ ] Report approvato QA/RA; backlog marcato completo; prossima produzione: CG-TER-001 definitivo

---

## 9. Task Summary Matrix

| Task ID | Title | Phase | Status | Estimate | SU | SRS | TP |
|---|---|---|---|---|---|---|---|
| TASK-01 | Scaffold repo, toolchain e gate layer | 0 | todo | M (8h) | — | 201, 1005 | TP-201a |
| TASK-02 | Store skeleton, prefs seed, CI PII-gate | 0 | todo | M (8h) | — | 101, 103, 1002–1003 | TP-1002, TP-1003 |
| TASK-03 | PhoneNumber | 1 | todo | M (8h) | SU-DOM-01-01 | 302, 304, 305 | TP-302, 304, 305, 701 |
| TASK-04 | ScreeningDecision | 1 | todo | S (4h) | SU-DOM-02-01 | 302–304, 306, 703 | TP-302–304, 306, 703 |
| TASK-05 | SmsEligibility | 1 | todo | S (4h) | SU-DOM-02-02 | 103, 304, 305, 501–502 | TP-305, 502 |
| TASK-06 | CallRecord | 1 | todo | M (8h) | SU-DOM-03-01 | 401–402 | TP-401, 402, 501 |
| TASK-07 | TrustedEntry | 1 | todo | M (8h) | SU-DOM-03-02 | 603–604, 701–702, 802 | TP-603–604, 701–702 |
| TASK-08 | AutoReplyTemplate | 1 | todo | S (4h) | SU-DOM-04-01 | 101, 503 | TP-101, 503, 1102 |
| TASK-09 | ScreenIncomingCallUseCase | 2 | todo | L (16h) | SU-APP-01-01 | 201, 301–303, 306, 703, 1001, 1004 | TP-201b, 301, 1001, 1004 |
| TASK-10 | RecordRejectedCallUseCase | 2 | todo | S (4h) | SU-APP-02-01 | 401–402 | TP-303, 304, 401, 402 |
| TASK-11 | SendAutoReplyUseCase | 2 | todo | M (8h) | SU-APP-03-01 | 103, 501–502, 902 | TP-402, 501, 502, 902, 1102 |
| TASK-12 | TriageInboundSmsUseCase | 2 | todo | M (8h) | SU-APP-04-01 | 601 | TP-601, 1104 |
| TASK-13 | ClassifyNumberUseCase | 2 | todo | M (8h) | SU-APP-05-01 | 307, 603–604, 704 | TP-307, 603, 604, 704 |
| TASK-14 | ManageListsUseCase | 2 | todo | M (8h) | SU-APP-06-01 | 307, 701–702 | TP-701, 702 |
| TASK-15 | ConfigureSmsTemplateUseCase | 2 | todo | S (4h) | SU-APP-07-01 | 101–102, 503 | TP-101, 102, 503 |
| TASK-16 | ProtectionStatusUseCase | 2 | todo | S (4h) | SU-APP-08-01 | 202–203, 1004–1005 | TP-202, 203, 1005, 1004 |
| TASK-17 | CallScreeningAdapter | 3 | todo | L (16h) | SU-INF-01-01 | 201, 301–302, 306–307 | TP-301, 302, 1202 |
| TASK-18 | ContactsLookupAdapter | 3 | todo | S (4h) | SU-INF-02-01 | 203, 302–303 | TP-203, 303, 1101 |
| TASK-19 | SmsSenderAdapter | 3 | todo | M (8h) | SU-INF-03-01 | 203, 305, 501 | TP-305, 402, 501, 902 |
| TASK-20 | SmsInboxReaderAdapter | 3 | todo | M (8h) | SU-INF-04-01 | 203, 601 | TP-203, 601, 1104 |
| TASK-21 | LocalStoreAdapter | 3 | todo | L (16h) | SU-INF-05-01 | 101–103, 307, 401–403, 502–504, 603–604, 701, 705 | TP-101–103, 307, 401–403, 502, 701–702, 705, 1201 |
| TASK-22 | PlatformChannelBridge | 3 | todo | M (8h) | SU-INF-06-01 | (contratto §6) 307, 603–604, 902 | TP-307, 603–604, 704, 902 |
| TASK-23 | FlutterPresentation (6 superfici) | 3 | todo | L (16h) | SU-INF-07-01 | 103, 202–203, 503, 602, 701, 704, 801–802, 901–902, 1004–1005 | TP-202–203, 503, 602, 704, 801–802, 901, 1103–1104 |
| TASK-24 | DiagnosticsLogger | 3 | todo | S (4h) | SU-INF-08-01 | 901, 1002–1003 | TP-901, 1002, 1003 |
| TASK-25 | Tracer-bullet E2E su device | 4 | todo | L (16h) | — (verticale) | RF-1…RF-10 | TP-1101, 1102, 1104, 301, 1001 |
| TASK-26 | Coverage closure + TER + gate release | 4 | todo | M (8h) | — | Tutti | Tutti TP-101…TP-1203 |

**Totale stimato:** ≈ 196h (≈ 24.5 g-uomo). Nessuna scadenza promessa oltre le stime: lo scope cambia solo via Change Request sul documento toccato (regola Aldo).

---

*Rischi presidiati dal sequencing:* RSK-105 (Play) via TASK-02/16/20/gate TASK-26 con fallback solo-rifiuto; RSK-102 (timeout/ruolo/OEM) via TASK-09/17/25; RSK-103 (PII log) via TASK-02/24/gate TP-1003; RSK-106 (persistenza) via TASK-21/gate TP-1201; RSK-107 (costi SMS) via TASK-05/11/19; RSK-101/108/109 via TASK-13/23/25. AD-03 (scope SMS-read) chiusa entro TASK-20; AD-05 (disconnect vs silence) chiusa entro TASK-17; AMB-05 dual-SIM verificata best-effort in TASK-25.

*End of Document — CG-IPB-001 v0.1.0*
*Next in package: CG-TER-001 — Test Execution Report (prodotto dopo l'implementazione)*
