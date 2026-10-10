// TP-1004: STORE_UNWRITABLE mai drop silenzioso, retry al prossimo open.
// Eseguibile con: dart test/tp_1004_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/reject_store.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-1004 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

ScreeningVerdict _rejectVerdict() {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  return decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: false,
    inWhitelist: false,
    inBlacklist: false,
    roleHeld: true,
  ));
}

void main() {
  final t1 = DateTime.utc(2026, 5, 1, 10, 0, 0);
  final t2 = DateTime.utc(2026, 5, 1, 10, 0, 1);
  final verdict = _rejectVerdict();
  _check(verdict.shouldReject, 'fixture deve essere REJECT');

  // Store non scrivibile: due REJECT accodati, nessuno scartato.
  var store = const RejectStore(writable: false);
  var r1 = store.logDecision(
    verdict: verdict,
    normalizedNumber: '+393330000030',
    templateRef: 'default-v1',
    at: t1,
  );
  _check(r1.outcome == StoreWriteOutcome.queuedUnwritable,
      'REJECT su store non scrivibile deve accodare');
  store = r1.store;
  var r2 = store.logDecision(
    verdict: verdict,
    normalizedNumber: '+393330000031',
    templateRef: 'default-v1',
    at: t2,
  );
  _check(r2.outcome == StoreWriteOutcome.queuedUnwritable,
      'secondo REJECT deve accodare');
  store = r2.store;
  _check(store.committedCount == 0, 'nulla deve consolidarsi da non scrivibile');
  _check(store.pendingCount == 2, '2 scritture devono essere in coda, mai drop');

  // Un PASS mentre non scrivibile non accoda nulla.
  final hidden = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.restricted));
  final pass = decideScreening(ScreeningFacts(
    visibility: hidden,
    inContacts: false,
    inWhitelist: false,
    inBlacklist: false,
    roleHeld: true,
  ));
  final rp = store.logDecision(
    verdict: pass,
    normalizedNumber: 'anon',
    templateRef: 'default-v1',
    at: t1,
  );
  _check(rp.outcome == StoreWriteOutcome.ignoredPass, 'PASS non si accoda');
  store = rp.store;
  _check(store.pendingCount == 2, 'PASS non deve alterare la coda');

  // Retry al prossimo open scrivibile: riversa in ordine.
  store = store.open(writable: true);
  _check(store.pendingCount == 0, 'dopo retry la coda deve svuotarsi');
  _check(store.committedCount == 2, 'dopo retry attese 2 righe consolidate');
  _check(store.committed.entries[0].numberKey == '+393330000030',
      'ordine retry: prima riga attesa +393330000030');
  _check(store.committed.entries[1].numberKey == '+393330000031',
      'ordine retry: seconda riga attesa +393330000031');

  // Dopo il retry lo store torna a consolidare subito.
  final r3 = store.logDecision(
    verdict: verdict,
    normalizedNumber: '+393330000032',
    templateRef: 'default-v1',
    at: t2,
  );
  _check(r3.outcome == StoreWriteOutcome.stored, 'dopo open deve consolidare');
  store = r3.store;
  _check(store.committedCount == 3, 'attese 3 righe totali');

  stdout.writeln('TP-1004 PASSED: 2 accodate mai perse, retry in ordine, 3 righe totali');
}
