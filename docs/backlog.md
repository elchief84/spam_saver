# Call Guard — Implementation Plan Backlog

**Document ID:** CG-IPB-001
**Version:** 0.1.0
**Status:** draft
**Status vocabulary:** draft · pending_review · draft_revised · pending_approval · approved · superseded
**Date:** 2026-10-11
**Service:** `call-guard`
**IEC 62304 phases:** 5.5 - Software Unit Implementation · 5.6 - Software Integration Testing
**Trace parents:** CG-SRS-001 v0.1.0 · CG-ARCH-001 v0.1.0 · CG-SDS-001 v0.1.0 · CG-TP-001 v0.1.0
**Author:** Aldo (PM)

| Version | Date | Author | Change |
|---|---|---|---|
| 0.1.0 | 2026-10-11 | Aldo (PM) | Initial backlog from CG-SRS-001 + CG-ARCH-001 + CG-SDS-001 + CG-TP-001; 29 tracer tasks |

---

## 1. Overview — valore per utente e business

Call Guard (Android 10+, Kotlin nativo + UI Flutter, solo on-device) protegge da chiamate sconosciute: rifiuta prima dello squillo i numeri visibili non in rubrica/whitelist, registra il tentativo, invia un SMS automatico configurabile, e all'apertura mostra le risposte con CTA **ACCETTA (whitelist) / RIFIUTA (blacklist)**.

Utenti concreti e benefici misurabili:

- **UN-01 Non essere disturbato:** 0 squilli da sconosciuti con ruolo attivo; legittimi (rubrica/whitelist) senza ritardo percepibile.
- **UN-02 Traccia consultabile:** ogni rifiuto = 1 riga (numero, data/ora, esito, stato SMS, note), ordinata discendente, persistente a reboot/update.
- **UN-03 Classificazione rapida:** triage SMS foreground → whitelist/blacklist in 1–2 tocchi, effettivo dalla chiamata successiva, con undo.
- **UN-04 Testo SMS personalizzabile:** default precompilato, 1 segmento GSM-7, validato, persistito.
- **UN-05 Liste gestibili:** whitelist/blacklist con profilo (nome, note, categoria, data, source), mutua esclusione.
- **UN-06 Privacy on-device:** nessun dato lascia il dispositivo; nessun PII nei log.

Default SMS (SRS-101, immutabile qui): "La chiamata è stata automaticamente rifiutata dal ricevente perché il suo numero è sconosciuto, le preghiamo di inviare un sms con le informazioni necessarie alla sua identificazione."

Fuori perimetro: iOS, backend/cloud/sync, chiamate in uscita. Piattaforma vincolante: `CallScreeningService` + `ROLE_CALL_SCREENING`, Android 10+; Flutter mai nel path decisionale.

---

## 2. Governance

**Default task status:** `todo`
**Status values:** `todo · in_progress · blocked · review · done`

Implementation rules (da template, vincolanti):

1. Nessun codice per un task finché le sue dipendenze non sono completate e riviste.
2. Ogni task dichiara `source_files` e file di test mappati.
3. Il Domain layer (PHASE-01) è completato prima che inizi l'Application layer (PHASE-02).
4. L'Application layer è completato prima che inizi l'Infrastructure layer (PHASE-03).
5. Nessun task viola la direzione delle dipendenze: Domain ← Application ← Infrastructure. Gli adapter implementano esattamente una porta definita dall'Application; la policy vive solo nel Domain (Kotlin `:domain`, zero `android.*`/`flutter.*`).
6. Regole Aldo: ogni task ha **stima obbligatoria**, **acceptance criteria** e **dipendenze esplicite**; scope change = Change Request, mai edit silenzioso.

---

## 3. Phases

| ID | Title | Description | Exit gate |
|---|---|---|---|
| PHASE-00 | Foundation and Project Setup | Bootstrap struttura canonica (modulo Kotlin `:domain`, `:app`, nativo Android, Flutter), toolchain, fixture di test, snapshot in-memory, CI gates (detekt, forbidden-import, log-grep). Nessuna policy di prodotto qui. | Build verde + suite vuota verde + gate PII attivo |
| PHASE-01 | Domain Layer | Logica pura (normalizzazione, precedenza, eligibility, entità, template). Zero I/O. | 6 SU domain + UT verdi, coverage policy 100% branch |
| PHASE-02 | Application Layer | Use case contro porte + fake. Screening off-path (record/SMS dopo la decisione). | 8 use case + IT con fake verdi |
| PHASE-03 | Infrastructure Layer | Adapter (screening, contatti, SMS send/read, Room, channel, UI, logger). | E2E su emulatore + Room reale verdi |
| PHASE-04 | Verification and Hardening | Integrazione, perf/timeout, privacy, persistenza, Play readiness, OEM matrix. | 5 gate di release verdi (TP-301/TP-1202, TP-1003, TP-1201, TP-1203, TP-1101) |

Stima totale: **~46 giorni-dev** (1 dev Android+Flutter; parallelizzabile a ~25 gg con 2 dev dopo PHASE-01). Nessuna scadenza promessa oltre le stime per-task.

---

## 4. Tasks — PHASE-00 Foundation

### TASK-001 — Bootstrap progetto + CI gates
- **Status:** todo · **Phase:** PHASE-00 · **Depends on:** [] · **Stima:** 3 gg
- **IEC 62304:** 5.5 · **SDS ref:** §2, §3.5, §10.5 (struttura, schema baseline)
- **SRS trace:** SRS-201, SRS-1005 · **TP trace:** TP-201, TP-1005
- **Source files:** `android/settings.gradle`, `android/app/build.gradle (minSdk 29)`, `android/app/src/main/AndroidManifest.xml`, `lib/main.dart`, `test/smoke_test.dart`
- **Implementation notes:** `minSdk 29`, `allowBackup=false`, nessun `INTERNET`; channel name `call_guard/bridge_v1`; Room `exportSchema=true`; CI: `./gradlew :domain:test`, `flutter test`, detekt + forbidden-import (`android.*` vietato in `domain/`, `application/`), grep PII-canarino.
- **Acceptance criteria:** build APK debug ok; suite vuota verde; import vietato fa fallire la build per prova.
- **Definition of done:** compila zero errori; lint zero errori; struttura `:domain/:app/native/flutter` verificata in review.
- **Verification:** `./gradlew :domain:test` · `flutter test` · `./gradlew detekt`
- **Deliverables:** scheletro progetto + pipeline CI verde

### TASK-002 — Fixture canoniche + Fake doubles + snapshot harness
- **Status:** todo · **Phase:** PHASE-00 · **Depends on:** [TASK-001] · **Stima:** 2 gg
- **IEC 62304:** 5.5 · **SDS ref:** §10 (porte), §6.3 (wire types)
- **SRS trace:** SRS-302, SRS-304, SRS-305 · **TP trace:** TP-302, TP-304, TP-305 (§3 fixture)
- **Source files:** `test-fixtures/numbers.kt (3330000001, 3330000002, 40400, BANCA, hidden)`, `android/app/src/test/fakes/FakeSmsManager.kt`, `android/app/src/test/fakes/FakeContactsProvider.kt`, `android/app/src/test/fakes/FakeCallScreeningCall.kt`
- **Implementation notes:** fixture con numerazioni di laboratorio soltanto, mai numeri reali; orologio fake per ordinamenti; snapshot in-memory (`blacklistSet`, `whitelistSet`) con rebuild sincrono.
- **Acceptance criteria:** ogni fake espone success/fail/skipped; i numeri-canarino sono cercabili dal gate log.
- **Definition of done:** fixture usate da tutti i task successivi senza duplicazione; review ok.
- **Verification:** `./gradlew :domain:test --tests "*Fixture*"` · `flutter test`
- **Deliverables:** fixture + fake + harness snapshot

---

## 5. Tasks — PHASE-01 Domain Layer (puro Kotlin `:domain`, nessun I/O)

### TASK-010 — PhoneNumber: normalizzazione + visibilità + dialability
- **Status:** todo · **Phase:** PHASE-01 · **Depends on:** [TASK-001, TASK-002] · **Stima:** 2 gg
- **IEC 62304:** 5.5 · **SDS ref:** §8.1 SU-DOM-01-01 · **SU:** SU-DOM-01-01
- **SRS trace:** SRS-302, SRS-304, SRS-305 · **TP trace:** TP-302, TP-304, TP-305, TP-701
- **Source files:** `domain/src/main/kotlin/com/callguard/domain/PhoneNumber.kt`, `domain/src/test/kotlin/com/callguard/domain/PhoneNumberTest.kt`
- **Implementation notes:** totale, mai throw: `RESTRICTED/UNKNOWN→Hidden`; strip `[ - . ( ) /]`; alpha→non-dialable; short-code euristica `^[0-9]{3,6}$`+piano nazionale (fixture `40400` non-dialable); `^\+?[0-9]{6,15}$`→dialable; `00→+`; equivalenza `+39/0039/0 trunk`. Pattern lineari, no backtracking.
- **Acceptance criteria:** 5 input TP-305 classificati correttamente; hidden/vuoto mai SMS; `+393330000030` dialable.
- **Definition of done:** UT verdi, branch coverage 100%, detekt pulito, vietato `android.*`.
- **Verification:** `./gradlew :domain:test --tests "*PhoneNumber*"`
- **Deliverables:** `PhoneNumber.kt` + UT

### TASK-011 — ScreeningDecision: precedenza blacklist > pass > reject
- **Status:** todo · **Phase:** PHASE-01 · **Depends on:** [TASK-010] · **Stima:** 1.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §8.1 SU-DOM-02-01 · **SU:** SU-DOM-02-01
- **SRS trace:** SRS-302, SRS-303, SRS-304, SRS-306, SRS-703 · **TP trace:** TP-302, TP-303, TP-304, TP-306, TP-703
- **Source files:** `domain/.../domain/ScreeningDecision.kt`, `domain/.../ScreeningDecisionTest.kt`
- **Implementation notes:** funzione totale, ordine normativo: `!role→PASS/NO_ROLE` → `Hidden/Empty→PASS/ANONYMOUS` → `blacklist→REJECT` (prevale su rubrica, AMB-04) → `contacts|whitelist→PASS` → else `REJECT/UNKNOWN`. `SILENCE_FALLBACK` mai qui (è fallback adapter AD-05).
- **Acceptance criteria:** 10/10 combinazioni TP-302 + 6/6 TP-703 conformi; nessun rifiuto senza ruolo.
- **Definition of done:** come TASK-010.
- **Verification:** `./gradlew :domain:test --tests "*ScreeningDecision*"`
- **Deliverables:** `ScreeningDecision.kt` + UT parametrica

### TASK-012 — SmsEligibility: gate puro dell'invio
- **Status:** todo · **Phase:** PHASE-01 · **Depends on:** [TASK-010] · **Stima:** 1 gg
- **IEC 62304:** 5.5 · **SDS ref:** §8.1 SU-DOM-02-02 · **SU:** SU-DOM-02-02
- **SRS trace:** SRS-103, SRS-304, SRS-305, SRS-501, SRS-502 · **TP trace:** TP-305, TP-501, TP-502
- **Source files:** `domain/.../domain/SmsEligibility.kt`, `domain/.../SmsEligibilityTest.kt`
- **Implementation notes:** ordine: `Hidden→Skipped(HIDDEN)` → `!dialable→Skipped(NON_DIALABLE)` → `BLACKLIST && !flag→Skipped(BLACKLISTED)` → else `Eligible`. Nuovo skip reason = nuova riga registry §7 + ledger enum + TP.
- **Acceptance criteria:** default flag OFF → blacklist skipped; hidden/short-code mai eligible.
- **Definition of done:** come TASK-010.
- **Verification:** `./gradlew :domain:test --tests "*SmsEligibility*"`
- **Deliverables:** `SmsEligibility.kt` + UT

### TASK-013 — CallRecord: entità + macchina stati ledger SMS
- **Status:** todo · **Phase:** PHASE-01 · **Depends on:** [TASK-010, TASK-011] · **Stima:** 1.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §8.2 SU-DOM-03-01, §3.1 · **SU:** SU-DOM-03-01
- **SRS trace:** SRS-401, SRS-402 · **TP trace:** TP-401, TP-402
- **Source files:** `domain/.../domain/CallRecord.kt`, `domain/.../CallRecordTest.kt`
- **Implementation notes:** `create` solo se `REJECT` (contacts-pass mai crea riga); `event_id=UUIDv4` (chiave idempotenza); macchina `pending→sent|failed|skipped`, `failed→sent|failed` (retry max 1), `sent/skipped` terminali; solo `template_ref=sha16`, mai body.
- **Acceptance criteria:** 2 chiamate stesso numero/minuto = 2 righe; `notes=""` default; terminali irremovibili.
- **Definition of done:** come TASK-010.
- **Verification:** `./gradlew :domain:test --tests "*CallRecord*"`
- **Deliverables:** `CallRecord.kt` + UT macchina stati

### TASK-014 — TrustedEntry: mutua esclusione + move semantics
- **Status:** todo · **Phase:** PHASE-01 · **Depends on:** [TASK-010] · **Stima:** 1.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §8.2 SU-DOM-03-02, §3.2 · **SU:** SU-DOM-03-02
- **SRS trace:** SRS-603, SRS-604, SRS-701, SRS-702, SRS-802 · **TP trace:** TP-603, TP-604, TP-701, TP-702
- **Source files:** `domain/.../domain/TrustedEntry.kt`, `domain/.../TrustedEntryTest.kt`
- **Implementation notes:** chiave `normalized_number` UNIQUE cross-lista; `addToList` richiede `confirmedMove` se in altra lista (conferma UI RSK-108); stessa lista = edit; `remove` mai cancella history; `category` free-text v1 (TQ-03 compatibile).
- **Acceptance criteria:** mai doppia appartenenza; move preserva `date_added`, aggiorna `last_modified`; `+39 3330000099`≡`333 000 0099`.
- **Definition of done:** come TASK-010.
- **Verification:** `./gradlew :domain:test --tests "*TrustedEntry*"`
- **Deliverables:** `TrustedEntry.kt` + UT

### TASK-015 — AutoReplyTemplate: default + validazione + segmenti
- **Status:** todo · **Phase:** PHASE-01 · **Depends on:** [TASK-001] · **Stima:** 1 gg
- **IEC 62304:** 5.5 · **SDS ref:** §8.2 SU-DOM-04-01, §4.1 · **SU:** SU-DOM-04-01
- **SRS trace:** SRS-101, SRS-503 · **TP trace:** TP-101, TP-503, TP-1102
- **Source files:** `domain/.../domain/AutoReplyTemplate.kt`, `domain/.../AutoReplyTemplateTest.kt`
- **Implementation notes:** costante `DEFAULT_TEMPLATE` carattere-esatta (unica fonte); `validate`: trim→vuoto=`VALIDATION_EMPTY_TEMPLATE`, >480=`VALIDATION_TEMPLATE_TOO_LONG`, encoding GSM-7/UCS-2 per 3GPP 23.038; default verificato 1 segmento GSM-7; save rifiutato conserva prior.
- **Acceptance criteria:** default identico carattere-per-carattere; vuoto/spazi/oltre-limite rifiutati; contatore segmenti esposto.
- **Definition of done:** come TASK-010.
- **Verification:** `./gradlew :domain:test --tests "*AutoReplyTemplate*"`
- **Deliverables:** `AutoReplyTemplate.kt` + UT

---

## 6. Tasks — PHASE-02 Application Layer (use case contro porte, fake)

### TASK-020 — ScreenIncomingCallUseCase (orchestratore time-critical)
- **Status:** todo · **Phase:** PHASE-02 · **Depends on:** [TASK-010, TASK-011, TASK-013] · **Stima:** 2.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §9.1 SU-APP-01-01 · **SU:** SU-APP-01-01
- **SRS trace:** SRS-201, SRS-301, SRS-302, SRS-303, SRS-306, SRS-703, SRS-1001, SRS-1004 · **TP trace:** TP-201, TP-301, TP-302, TP-1001
- **Source files:** `application/.../ScreenIncomingCallUseCase.kt`, `application/.../ScreenIncomingCallUseCaseTest.kt (fake snapshot+clock)`
- **Implementation notes:** solo snapshot in-memory, no rete/Room/SMS prima del return (target <500 ms p99); dedup callback OS per `callId`→1 `event_id`; `ROLE_MISSING`/`SCREENING_TIMEOUT`/eccezione→fail-open PASS + contatore scrubbed `{screening_event_id, origin, elapsed_ms}`, mai numero.
- **Acceptance criteria:** decisione entro timeout con 10k contatti + 1k liste; rete disabilitata = stesso comportamento; timeout→PASS senza record fasullo.
- **Definition of done:** IT con fake verdi; nessun import `android.*`/Room; review.
- **Verification:** `./gradlew :app:test --tests "*ScreenIncoming*"`, run con rete disabilitata
- **Deliverables:** use case + test fake

### TASK-021 — RecordRejectedCallUseCase (1 riga per rifiuto)
- **Status:** todo · **Phase:** PHASE-02 · **Depends on:** [TASK-013, TASK-020] · **Stima:** 1 gg
- **IEC 62304:** 5.5 · **SDS ref:** §9.1 SU-APP-02-01 · **SU:** SU-APP-02-01
- **SRS trace:** SRS-401, SRS-402 · **TP trace:** TP-401, TP-402
- **Source files:** `application/.../RecordRejectedCallUseCase.kt`, test con `FakeRejectedCallRepository`
- **Implementation notes:** PASS/anonimo→rifiuto silenzioso (mai log, SRS-303/304); insert transazionale; `STORE_UNWRITABLE`→retry al prossimo open, mai drop silenzioso; forward `event_id` a TASK-022 senza await.
- **Acceptance criteria:** TP-401: 2 rifiuti = 2 righe complete con `outcome=rejected`, `retry_count=0`.
- **Definition of done:** come TASK-020.
- **Verification:** `./gradlew :app:test --tests "*RecordRejected*"`
- **Deliverables:** use case + test

### TASK-022 — SendAutoReplyUseCase (exactly-once + 1 retry manuale)
- **Status:** todo · **Phase:** PHASE-02 · **Depends on:** [TASK-012, TASK-015, TASK-021] · **Stima:** 2 gg
- **IEC 62304:** 5.5 · **SDS ref:** §9.1 SU-APP-03-01, §7 · **SU:** SU-APP-03-01
- **SRS trace:** SRS-103, SRS-501, SRS-502, SRS-902 · **TP trace:** TP-501, TP-502, TP-902, TP-1102
- **Source files:** `application/.../SendAutoReplyUseCase.kt`, test con `FakeSmsSender + FakeTemplateStore`
- **Implementation notes:** auto: `status!=pending→SMS_DUPLICATE_SUPPRESSED`; eligibility prima di ogni send; `!SEND_SMS→failed/no_permission`; 1 solo tentativo, mai auto-retry; retry manuale: `sent→RETRY_REFUSED_ALREADY_SENT`, `retry_count==1→RETRY_REFUSED_EXHAUSTED`, `skipped` non ritentabile; template letto dai prefs (SRS-102), `template_ref=sha16`.
- **Acceptance criteria:** doppio evento stesso id = 1 invio; blacklist flag OFF = `skipped/blacklisted`; totale per record ≤2 (originale+1 retry), zero background.
- **Definition of done:** come TASK-020.
- **Verification:** `./gradlew :app:test --tests "*SendAutoReply*"`
- **Deliverables:** use case + test idempotenza/retry

### TASK-023 — TriageInboundSmsUseCase (foreground, linked)
- **Status:** todo · **Phase:** PHASE-02 · **Depends on:** [TASK-010, TASK-013] · **Stima:** 1.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §9.1 SU-APP-04-01 · **SU:** SU-APP-04-01
- **SRS trace:** SRS-601 · **TP trace:** TP-601, TP-1104
- **Source files:** `application/.../TriageInboundSmsUseCase.kt`, test con `FakeSmsInboxReader`
- **Implementation notes:** `!READ_SMS→SMS_ACCESS_MISSING`, legge nulla; finestra `date>=watermark`, cap 200 newest-first; non-normalizzabile→`unlinked` senza CTA; in lista→`classified`; mai rifiutato→`unlinked`; dedup `provider_msg_id`; watermark avanzato.
- **Acceptance criteria:** TP-601: solo A (rifiutato, non classificato) in coda pending con link al record; B/C esclusi correttamente.
- **Definition of done:** come TASK-020.
- **Verification:** `./gradlew :app:test --tests "*Triage*"`
- **Deliverables:** use case + test

### TASK-024 — ClassifyNumberUseCase (commit sincrono, SRS-307)
- **Status:** todo · **Phase:** PHASE-02 · **Depends on:** [TASK-014, TASK-023] · **Stima:** 1.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §9.2 SU-APP-05-01 · **SU:** SU-APP-05-01
- **SRS trace:** SRS-307, SRS-603, SRS-604, SRS-704 · **TP trace:** TP-307, TP-603, TP-604, TP-704
- **Source files:** `application/.../ClassifyNumberUseCase.kt`, test transazionale con fake repo
- **Implementation notes:** `source=sms_classification|call_history`; stessa transazione: upsert lista + `triage→classified` + rebuild snapshot prima del return; `effect` string ("squillerà normalmente"/"sempre rifiutato"); altra lista senza `confirmedMove`→`NEEDS_CONFIRM`; `STORE_UNWRITABLE`→nessuno stato parziale.
- **Acceptance criteria:** sequenza reject→(whitelist)→pass→(blacklist)→reject senza restart; pendenza rimossa.
- **Definition of done:** come TASK-020.
- **Verification:** `./gradlew :app:test --tests "*ClassifyNumber*"`
- **Deliverables:** use case + test

### TASK-025 — ManageListsUseCase (CRUD + profili)
- **Status:** todo · **Phase:** PHASE-02 · **Depends on:** [TASK-014, TASK-024] · **Stima:** 1.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §9.2 SU-APP-06-01 · **SU:** SU-APP-06-01
- **SRS trace:** SRS-307, SRS-701, SRS-702 · **TP trace:** TP-701, TP-702
- **Source files:** `application/.../ManageListsUseCase.kt`, test fake
- **Implementation notes:** `source=manual`; `remove` non tocca history; `edit` solo nome/note/categoria (numero immutabile); ogni mutazione rebuild snapshot sincrono + effect statement.
- **Acceptance criteria:** TP-701/702: CRUD completi, unicità normalizzata, move registrato, mai doppia appartenenza.
- **Definition of done:** come TASK-020.
- **Verification:** `./gradlew :app:test --tests "*ManageLists*"`
- **Deliverables:** use case + test

### TASK-026 — ConfigureSmsTemplateUseCase
- **Status:** todo · **Phase:** PHASE-02 · **Depends on:** [TASK-015] · **Stima:** 1 gg
- **IEC 62304:** 5.5 · **SDS ref:** §9.2 SU-APP-07-01 · **SU:** SU-APP-07-01
- **SRS trace:** SRS-101, SRS-102, SRS-503 · **TP trace:** TP-101, TP-102, TP-503
- **Source files:** `application/.../ConfigureSmsTemplateUseCase.kt`, test con `FakeTemplateStore`
- **Implementation notes:** `get/set/restoreDefault`; errore→field error, prior conservato; invio successivo usa nuovo testo (SRS-102).
- **Acceptance criteria:** vuoto/oltre-limite rifiutati; restore ripristina default esatto; segmenti esposti.
- **Definition of done:** come TASK-020.
- **Verification:** `./gradlew :app:test --tests "*ConfigureSmsTemplate*"`
- **Deliverables:** use case + test

### TASK-027 — ProtectionStatusUseCase (ruolo + permessi + OS)
- **Status:** todo · **Phase:** PHASE-02 · **Depends on:** [TASK-020] · **Stima:** 1 gg
- **IEC 62304:** 5.5 · **SDS ref:** §9.2 SU-APP-08-01, §5 · **SU:** SU-APP-08-01
- **SRS trace:** SRS-202, SRS-203, SRS-1004, SRS-1005 · **TP trace:** TP-202, TP-203, TP-1004, TP-1005
- **Source files:** `application/.../ProtectionStatusUseCase.kt`, test con `FakeProtectionStateProvider`
- **Implementation notes:** `protectionActive=osSupported && hasRole`; `degraded` se bit SMS/contatti negati; deep-link role/settings; mai dichiara protezione senza ruolo; `osApi<29→OS_UNSUPPORTED`.
- **Acceptance criteria:** banner bloccante + singola azione role-request; ogni permesso negato = messaggio dedicato.
- **Definition of done:** come TASK-020.
- **Verification:** `./gradlew :app:test --tests "*ProtectionStatus*"`
- **Deliverables:** use case + test

---

## 7. Tasks — PHASE-03 Infrastructure Layer (adapter, 1 porta = 1 adapter)

### TASK-030 — CallScreeningAdapter (`onScreenCall`, attuation)
- **Status:** todo · **Phase:** PHASE-03 · **Depends on:** [TASK-020, TASK-027] · **Stima:** 2.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §10.1 SU-INF-01-01, AD-05 · **SU:** SU-INF-01-01
- **SRS trace:** SRS-201, SRS-301, SRS-307, SRS-1001 · **TP trace:** TP-201, TP-301, TP-1202
- **Source files:** `android/app/src/main/kotlin/com/callguard/native/CallScreeningAdapter.kt`, `android/app/src/androidTest/.../CallScreeningTest.kt (Robolectric)`
- **Implementation notes:** snapshot-only, no I/O/rete prima del return; `CallResponse(disallow)`; fallback `silence` se disconnect rifiutato da OEM + ledger `actuation`; diagnostica scrubbed. AD-05 chiuso qui dopo matrice device/SIM (AMB-05).
- **Acceptance criteria:** 20/20 decisioni entro timeout, 0 squilli sconosciuti, 0 accessi rete; legittime senza ritardo.
- **Definition of done:** IT Robolectric verdi; review TA; fallback branch deterministico documentato.
- **Verification:** `./gradlew :app:connectedAndroidTest --tests "*CallScreening*"` · trace `elapsedRealtime`
- **Deliverables:** adapter + test instrumented

### TASK-031 — ContactsLookupAdapter (read-only + snapshot)
- **Status:** todo · **Phase:** PHASE-03 · **Depends on:** [TASK-020] · **Stima:** 1 gg
- **IEC 62304:** 5.5 · **SDS ref:** §10.2 SU-INF-02-01 · **SU:** SU-INF-02-01
- **SRS trace:** SRS-203, SRS-302, SRS-303 · **TP trace:** TP-203, TP-302, TP-303
- **Source files:** `.../native/ContactsLookupAdapter.kt`, `.../ContactsLookupTest.kt`
- **Implementation notes:** `PhoneLookup` presenza booleana soltanto, mai copia contatti; `!READ_CONTACTS→PERMISSION_DENIED_CONTACTS` + handling unknown; rebuild snapshot a boot/ogni write liste.
- **Acceptance criteria:** contatti passano senza righe/SMS; negato = notice + link impostazioni.
- **Definition of done:** IT verdi, nessun PII oltre snapshot.
- **Verification:** `./gradlew :app:test --tests "*ContactsLookup*"`
- **Deliverables:** adapter + test

### TASK-032 — SmsSenderAdapter (`SmsManager`, idempotenza)
- **Status:** todo · **Phase:** PHASE-03 · **Depends on:** [TASK-022] · **Stima:** 1.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §10.3 SU-INF-03-01 · **SU:** SU-INF-03-01
- **SRS trace:** SRS-203, SRS-305, SRS-501 · **TP trace:** TP-402, TP-501, TP-902
- **Source files:** `.../native/SmsSenderAdapter.kt`, test con `FakeSmsManager (success/NO_SERVICE/NULL_PDU)`
- **Implementation notes:** porta `event_id`; `sendTextMessage`/`sendMultipart` + intent; mappa `NO_SERVICE/NULL_PDU/radio→failed`; short-code/alpha guard redundante; nessun auto-retry.
- **Acceptance criteria:** mapping ledger corretto; zero invii verso non-dialable.
- **Definition of done:** IT verdi.
- **Verification:** `./gradlew :app:test --tests "*SmsSender*"`
- **Deliverables:** adapter + test

### TASK-033 — SmsInboxReaderAdapter (foreground scoped)
- **Status:** todo · **Phase:** PHASE-03 · **Depends on:** [TASK-023] · **Stima:** 1.5 gg
- **IEC 62304:** 5.5 · **SDS ref:** §10.4 SU-INF-04-01, AD-03/AD-04 · **SU:** SU-INF-04-01
- **SRS trace:** SRS-203, SRS-601 · **TP trace:** TP-601, TP-1203
- **Source files:** `.../native/SmsInboxReaderAdapter.kt`, test provider fake
- **Implementation notes:** query inbox solo foreground, scoped a numeri history; `!READ→PERMISSION_DENIED_SMS_READ`; AD-03: documenta scelta scope minimo vs Consent/Retriever API prima del sign-off (gate Play); nessun background listener di default (AD-04 baseline).
- **Acceptance criteria:** negato = vista guidance; scoped read dimostrato; decisione AD-03 registrata.
- **Definition of done:** IT verdi + nota AD-03 approvata.
- **Verification:** `./gradlew :app:test --tests "*SmsInbox*"`
- **Deliverables:** adapter + test + nota AD-03

### TASK-034 — LocalStoreAdapter (Room v1 + prefs + migrazioni)
- **Status:** todo · **Phase:** PHASE-03 · **Depends on:** [TASK-021, TASK-024, TASK-025, TASK-026] · **Stima:** 3 gg
- **IEC 62304:** 5.5 · **SDS ref:** §10.5 SU-INF-05-01, §3 · **SU:** SU-INF-05-01
- **SRS trace:** SRS-101, SRS-102, SRS-103, SRS-307, SRS-401, SRS-402, SRS-403, SRS-502, SRS-603, SRS-604, SRS-701, SRS-705, SRS-801, SRS-1002 · **TP trace:** TP-102, TP-401, TP-403, TP-701, TP-705, TP-801, TP-1201
- **Source files:** `.../store/AppDatabase.kt`, `.../store/RejectedCallDao.kt`, `.../store/TrustedEntryDao.kt`, `.../store/SmsTriageDao.kt`, `.../store/PrefsStore.kt`, `schemas/call_guard.db.v1.json`, `.../MigrationTest.kt`
- **Implementation notes:** tabelle §3.1–3.3 + CHECK (`retry 0..1`, enum); `rejected_calls` mai aggregate; removal liste mai cancella history; rebuild snapshot nella stessa transazione (SRS-307); seed `cg_sms_template_text`=default + `cg_blacklist_sms_enabled=false`; `exportSchema=true`.
- **Acceptance criteria:** kill/reboot/update conservano tutto; ordinamento discendente; scrittura interrotta = rollback.
- **Definition of done:** Room in-memory + su disco verdi; migration test verde.
- **Verification:** `./gradlew :app:test --tests "*Store* *Migration*"` · `flutter test`
- **Deliverables:** DB v1 + DAO + prefs + schema JSON

### TASK-035 — PlatformChannelBridge (`bridge_v1`, 15 metodi)
- **Status:** todo · **Phase:** PHASE-03 · **Depends on:** [TASK-024, TASK-025, TASK-026, TASK-034] · **Stima:** 2 gg
- **IEC 62304:** 5.5 · **SDS ref:** §10.6 SU-INF-06-01, §6 · **SU:** SU-INF-06-01
- **SRS trace:** SRS-307, SRS-603, SRS-604, SRS-902 (carrier) · **TP trace:** TP-307, TP-603, TP-604, TP-902
- **Source files:** `.../native/PlatformChannelBridge.kt`, `lib/bridge/bridge_v1.dart`, `test/bridge_test.dart`
- **Implementation notes:** metodi `cg/v1/*` (§6.2, 15 voci); codec: numeri canonici string, timestamp ISO8601, enum lowercase; `classify/manage/retry` ritornano dopo commit+snapshot; envelope errore `{code,message,action}`, mai stack/PII; `bridge_v2` per breaking futuri.
- **Acceptance criteria:** tutti i metodi round-trip; `classify` sincrono effettivo; errori mappati da §7.
- **Definition of done:** test bridge Dart+Kotlin verdi; Dart senza logica screening (TP-201a).
- **Verification:** `flutter test test/bridge_test.dart` · `./gradlew :app:test --tests "*Bridge*"`
- **Deliverables:** bridge + codec + test

### TASK-036 — FlutterPresentation (6 superfici)
- **Status:** todo · **Phase:** PHASE-03 · **Depends on:** [TASK-027, TASK-035] · **Stima:** 4 gg
- **IEC 62304:** 5.5 · **SDS ref:** §10.7 SU-INF-07-01 · **SU:** SU-INF-07-01
- **SRS trace:** SRS-202, SRS-203, SRS-503, SRS-601, SRS-602, SRS-701, SRS-704, SRS-801, SRS-802, SRS-901, SRS-902, SRS-1004, SRS-1005 · **TP trace:** TP-202, TP-503, TP-602, TP-704, TP-801, TP-802, TP-901
- **Source files:** `lib/screens/{protection,history,triage,lists,profile,settings_sms}.dart`, `lib/widgets/{cta,ledger_badge}.dart`, `integration_test/app_test.dart`
- **Implementation notes:** onboarding blocco-ruolo; history/whitelist/blacklist con filtro sottostringa + sort desc; triage con esattamente 2 CTA + confirm+undo (RSK-108); editor template con contatore segmenti; dettaglio profilo (linked history, edit nome/note/categoria); retry manuale sulla riga; nessun duplicato policy (render-only).
- **Acceptance criteria:** CTA visibili senza menu; 1 tap promo da history; undo funzionante; filtro identico sulle 3 liste; TP-602 label esatte + a11y.
- **Definition of done:** `flutter test` + Espresso triage verdi; review UX.
- **Verification:** `flutter test` · `./gradlew :app:connectedAndroidTest --tests "*Presentation*"`
- **Deliverables:** 6 schermate + widget + E2E base

### TASK-037 — DiagnosticsLogger (scrub PII + contatori)
- **Status:** todo · **Phase:** PHASE-03 · **Depends on:** [TASK-030, TASK-032] · **Stima:** 1 gg
- **IEC 62304:** 5.5 · **SDS ref:** §10.8 SU-INF-08-01, §7 · **SU:** SU-INF-08-01
- **SRS trace:** SRS-901, SRS-1002, SRS-1003 · **TP trace:** TP-901, TP-1002, TP-1003
- **Source files:** `.../native/DiagnosticsLogger.kt`, `.../DiagnosticsLoggerTest.kt`
- **Implementation notes:** `scrub()` allowlist context (mai numeri/nomi/body); log solo hash/prefix; contatori screening-OK/role-missing/timeout/SMS sent-failed-skipped; nessun analytics/crash con identificatori.
- **Acceptance criteria:** canarino mai in chiaro in logcat/file/crash; build rossa su leak (gate).
- **Definition of done:** log-inspection test verde; lint PII verde.
- **Verification:** `./gradlew :app:test --tests "*Diagnostics*"` · `adb logcat | grep -F <canarino>` = 0 match
- **Deliverables:** logger + gate

---

## 8. Tasks — PHASE-04 Verification and Hardening (IEC 5.6)

### TASK-040 — Perf screening + OEM matrix + fail-open
- **Status:** todo · **Phase:** PHASE-04 · **Depends on:** [TASK-030, TASK-031, TASK-036] · **Stima:** 2.5 gg
- **IEC 62304:** 5.6 · **SDS ref:** §9.1–10.1, AD-05 · **SU:** SU-APP-01-01, SU-INF-01-01
- **SRS trace:** SRS-301, SRS-1001, SRS-1004 · **TP trace:** TP-301, TP-1001, TP-1004, TP-1202
- **Source files:** `android/app/src/androidTest/.../ScreeningPerfTest.kt`, `docs/release/oem-matrix.md`
- **Implementation notes:** 20 chiamate sconosciute (10k contatti, 1k liste), p99 <500 ms; 5/20 con rete disabilitata; OEM battery-optimizer + revoca ruolo a caldo; legittime senza stallo; chiude AD-05+TQ-01/TQ-02 come non-blocking.
- **Acceptance criteria (gate):** 20/20 entro timeout; 0 squilli sconosciuti; 0 egress nel path; fail-open documentato rispettato.
- **Definition of done:** report misure + matrice API 29/31/33/35 + Pixel+1 OEM allegati.
- **Verification:** device fisico + proxy capture · `TP-301/TP-1202` verdi
- **Deliverables:** report perf + matrice OEM **[GATE]**

### TASK-041 — Privacy/security gates: zero-egress + no PII nei log
- **Status:** todo · **Phase:** PHASE-04 · **Depends on:** [TASK-034, TASK-036, TASK-037] · **Stima:** 2 gg
- **IEC 62304:** 5.6 · **SDS ref:** §7, §10.8 · **SU:** SU-INF-08-01, SU-INF-05-01
- **SRS trace:** SRS-901, SRS-1002, SRS-1003 · **TP trace:** TP-901, TP-1002, TP-1003
- **Source files:** `tools/pii_grep.sh`, `docs/release/privacy-checklist.md`
- **Implementation notes:** E2E completo (rifiuto+SMS+triage+CRUD) con proxy; manifest senza `INTERNET`/provider esportati; `allowBackup=false`; grep canarino su logcat+file+report; errori con azione, mai stack/PII extra.
- **Acceptance criteria (gate):** traffico PII 0 byte; 0 match PII in chiaro (suite rossa altrimenti); 3/3 superfici errore con azione.
- **Definition of done:** checklist firmata; gate in CI bloccante.
- **Verification:** `TP-1002/TP-1003/TP-901` verdi
- **Deliverables:** checklist privacy + gate CI **[GATE]**

### TASK-042 — Persistenza/migrazione/reboot senza perdite
- **Status:** todo · **Phase:** PHASE-04 · **Depends on:** [TASK-034] · **Stima:** 1.5 gg
- **IEC 62304:** 5.6 · **SDS ref:** §3, §10.5 · **SU:** SU-INF-05-01
- **SRS trace:** SRS-102, SRS-403, SRS-705 · **TP trace:** TP-102, TP-403, TP-705, TP-1201
- **Source files:** `.../StoreDurabilityTest.kt`
- **Implementation notes:** dataset completo (cronologia+liste+custom+flag); reboot, upgrade schema, kill durante scrittura (fault injection); versionamento schema esplicito.
- **Acceptance criteria (gate):** dataset identico dopo ogni scenario; mai mezza riga; nessun decisionale solo-in-memoria.
- **Definition of done:** test verdi su disco (non solo in-memory).
- **Verification:** `./gradlew :app:test --tests "*Durability* *Migration*"`
- **Deliverables:** test durability + schema v1 **[GATE]**

### TASK-043 — Triage E2E + costi SMS + undo (RSK-101/107/108/109)
- **Status:** todo · **Phase:** PHASE-04 · **Depends on:** [TASK-032, TASK-033, TASK-036] · **Stima:** 2.5 gg
- **IEC 62304:** 5.6 · **SDS ref:** §9 · **SU:** SU-APP-03-01, SU-APP-04-01, SU-APP-05-01
- **SRS trace:** SRS-302, SRS-303, SRS-501, SRS-502, SRS-503, SRS-601, SRS-602, SRS-603, SRS-604 · **TP trace:** TP-501, TP-502, TP-503, TP-601–TP-604, TP-902, TP-1101–TP-1104
- **Source files:** `integration_test/triage_cost_test.dart`, `docs/release/triage-ux.md`
- **Implementation notes:** 10 controlli (5 noti squillano / 5 sconosciuti mai); 5 rifiuti rapidi stesso numero = 5 SMS 1:1; default 1 segmento + contatore + conferma pre-primo-invio; triage mediano <30 s, errore indotto annullabile; notifica+deep-link con limite foreground dichiarato in-app.
- **Acceptance criteria (gate RSK-101):** 10/10 conformi; eventi:invii 1:1; zero doppi; undo ok; notifica→triage diretto.
- **Definition of done:** E2E manuale firmato su 2 SIM lab; video demo allegato (riuso per Play).
- **Verification:** `TP-501/502/603/604/1101/1102/1103/1104` verdi
- **Deliverables:** report triage/costi + video **[GATE]**

### TASK-044 — Play readiness + release gate (RSK-105)
- **Status:** todo · **Phase:** PHASE-04 · **Depends on:** [TASK-033, TASK-040, TASK-041] · **Stima:** 2 gg
- **IEC 62304:** 5.6 · **SDS ref:** AD-03, §5 · **SU:** SU-APP-08-01
- **SRS trace:** SRS-203, SRS-501 · **TP trace:** TP-203, TP-1203
- **Source files:** `docs/release/play-declaration.md`, `docs/release/fallback-no-sms.md`
- **Implementation notes:** declaration core-functionality (screening+auto-reply), video demo, informativa in-app, giustificazione `SEND_SMS`/`RECEIVE_SMS`, valutazione Consent/Retriever documentata; fallback solo-rifiuto+notifica senza `SEND_SMS` dimostrato.
- **Acceptance criteria (gate):** pacchetto declaration completo; fallback utile senza SMS; nessun submit production a gate rosso.
- **Definition of done:** checklist QA/RA firmata; CR aperta per qualsiasi futuro network/sync.
- **Verification:** `TP-1203` verde (manuale)
- **Deliverables:** declaration pack + fallback demo **[GATE]**

---

## 9. Dependency graph (tracer order)

```
TASK-001 → TASK-002 → {TASK-010, TASK-015}
TASK-010 → {TASK-011, TASK-012, TASK-014}
TASK-011 → TASK-013 → TASK-021 → TASK-022
TASK-015 → {TASK-012(debole), TASK-026}
PHASE-01 done → TASK-020 → {TASK-021, TASK-027}
TASK-023 → TASK-024 → TASK-025
PHASE-02 done → {TASK-030, TASK-031, TASK-032, TASK-033, TASK-034}
TASK-034 + TASK-024/025/026 → TASK-035 → TASK-036
{TASK-030, TASK-032} → TASK-037
PHASE-03 done → {TASK-040, TASK-041, TASK-042, TASK-043} → TASK-044
```

Cammino critico: 001→002→010→011→013→020→022→030→034→035→036→040→044.

---

## 10. Traceability summary (SRS→task, TP→task)

| SRS | Tasks | TP | Tasks |
|---|---|---|---|
| SRS-101 | 015, 026, 034 | TP-101/102/103 | 015, 026, 034 |
| SRS-102 | 026, 034, 042 | TP-201/202/203 | 001, 027, 031, 036, 044 |
| SRS-103 | 012, 022, 034 | TP-301/302/…/307 | 010–012, 020, 024, 030 |
| SRS-201 | 001, 020, 030 | TP-401/402/403 | 013, 021, 032, 034, 042 |
| SRS-202/203 | 027, 031–033, 036 | TP-501/502/503 | 012, 015, 022, 026, 043 |
| SRS-301/302 | 010, 011, 020, 030, 040 | TP-601–604 | 014, 023, 024, 033, 043 |
| SRS-303/304/305 | 010, 011, 012, 020, 032 | TP-701/702/703/704/705 | 010, 011, 014, 024, 025, 034 |
| SRS-306/307/703 | 011, 020, 024, 025, 030, 034, 035 | TP-801/802 | 034, 036 |
| SRS-401/402/403 | 013, 021, 034, 042 | TP-901/902 | 022, 036, 037, 041 |
| SRS-501/502/503/902 | 012, 015, 022, 026, 032, 035, 043 | TP-1001–1005 | 020, 027, 030, 036, 040, 041 |
| SRS-601/602/603/604 | 014, 023, 024, 033, 035, 036, 043 | TP-1101–1104 | 015, 020, 023, 036, 043 |
| SRS-701/702/704/705 | 014, 024, 025, 034, 036 | TP-1201/1202/1203 | 030, 034, 040, 041, 044 |
| SRS-801/802 | 014, 034, 036 | — | — |
| SRS-901/902/1001–1005 | 022, 027, 030, 036, 037, 040, 041 | — | — |

Copertura: ogni SRS-101…SRS-1005 ha ≥1 task; ogni SU (22) ha esattamente 1 task proprietario (010–015, 020–027, 030–037); ogni TP-101…TP-1203 è assegnato a ≥1 task PHASE-04 o al task proprietario.

---

## 11. Rischi e gate di release

| RSK | Controllo architetturale | Task | Gate |
|---|---|---|---|
| RSK-101 falso positivo | precedenza fissa + whitelist onboarding | 011, 020, 043 | TP-1101 verde |
| RSK-102 timeout/ruolo/OEM | snapshot-only, role gate, fail-open, matrice | 020, 027, 030, 040 | TP-301/TP-1202 verdi |
| RSK-103 PII nei log | scrub + log-gate bloccante | 037, 041 | TP-1003 verde |
| RSK-104 store disclosure | app-private, no provider, `allowBackup=false` | 034, 041 | TP-1002 verde |
| RSK-105 rigetto Play | scope minimo, feature-gate, declaration+fallback | 027, 033, 044 | TP-1203 verde |
| RSK-106 perdita persistenza | transazioni, snapshot sincrono, migrazioni | 021, 034, 042 | TP-1201 verde |
| RSK-107 SMS incontrollati | exactly-once, default OFF blacklist, 1 retry | 012, 022, 032, 043 | TP-1102 verde |
| RSK-108 misclassification | confirm+undo, label esplicite | 024, 036, 043 | TP-1103 verde |
| RSK-109 triage differito | notifica+badge+deep-link, limite dichiarato | 023, 043 | TP-1104 verde |

Aperti ereditati (non decisi qui): AD-03 scope SMS-read (chiuso in TASK-033), AD-05 fallback OEM (chiuso in TASK-030/040), AMB-05 dual-SIM best-effort, TQ-01 cap retention, TQ-02 anonimi, TQ-03 categorie — qualsiasi modifica a SRS/ARCH/SDS richiede Change Request.

---

*End of Document — CG-IPB-001 v0.1.0*
*Next: review PM→TA, poi approvazione QA/RA con i 5 gate verdi.*
