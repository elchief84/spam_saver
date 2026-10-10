// TP-103: pendenza accodata su store non scrivibile e rimossa al retry,
// poi la sequenza continua senza restart.
// Eseguibile con: dart test/tp_103_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/reject_store.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-103 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

ScreeningVerdict _reject() {
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

  var store = const RejectStore(writable: false);
  var r = store.logDecision(
    verdict: _reject(),
    normalizedNumber: '+393330000030',
    templateRef: 'default-v1',
    at: t1,
  );
  _check(r.outcome == StoreWriteOutcome.queuedUnwritable, 'deve accodare');
  store = r.store;
  _check(store.committedCount == 0, 'nulla consolidato da non scrivibile');
  _check(store.pendingCount == 1, 'atteso 1 pendente');

  // Retry al prossimo open: pendenza rimossa e riversata in ordine.
  store = store.open(writable: true);
  _check(store.pendingCount == 0, 'pendenza deve essere rimossa dopo retry');
  _check(store.committedCount == 1, 'attesa 1 riga dopo retry');
  _check(store.committed.entries.single.numberKey == '+393330000030',
      'riga dal pendente attesa +393330000030');
  _check(store.committed.entries.single.rejectedAt == t1,
      'retry deve conservare istante originale');

  // Senza restart la sequenza continua a consolidare subito.
  r = store.logDecision(
    verdict: _reject(),
    normalizedNumber: '+393330000031',
    templateRef: 'default-v1',
    at: t2,
  );
  _check(r.outcome == StoreWriteOutcome.stored, 'dopo open deve consolidare');
  store = r.store;
  _check(store.committedCount == 2, 'attese 2 righe totali');
  _check(store.pendingCount == 0, 'nessun nuovo pendente');

  stdout.writeln('TP-103 PASSED: pendenza rimossa al retry, sequenza continua = 2 righe');
}
