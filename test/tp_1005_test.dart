// TP-1005: integrazione store+coda sulla sequenza reject-pass-reject
// senza restart, con pendenza rimossa dopo classificazione.
// Eseguibile con: dart test/tp_1005_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/reject_store.dart';
import '../src/domain/review_queue.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-1005 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

ScreeningVerdict _rejectUnknown() {
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

ScreeningVerdict _passContact() {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000001', presentation: Presentation.allowed));
  return decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: true,
    inWhitelist: false,
    inBlacklist: false,
    roleHeld: true,
  ));
}

void main() {
  final t = DateTime.utc(2026, 5, 1, 10, 0, 0);
  var store = const RejectStore();
  var queue = const ReviewQueue();

  // 1) REJECT sconosciuto: riga + pendenza con link.
  final r1 = _rejectUnknown();
  var w = store.logDecision(
    verdict: r1,
    normalizedNumber: '+393330000030',
    templateRef: 'default-v1',
    at: t,
  );
  _check(w.outcome == StoreWriteOutcome.stored, 'REJECT deve loggare');
  store = w.store;
  queue = queue.queueIfUnclassified(
    verdict: r1,
    normalizedNumber: '+393330000030',
    rejectLink: 'reject-log#0',
  );
  _check(store.committedCount == 1, 'attesa 1 riga');
  _check(queue.length == 1, 'attesa 1 pendenza');

  // 2) PASS contatto: nessuna riga, nessuna pendenza.
  final p = _passContact();
  w = store.logDecision(
    verdict: p,
    normalizedNumber: '+393330000001',
    templateRef: 'default-v1',
    at: t,
  );
  _check(w.outcome == StoreWriteOutcome.ignoredPass, 'PASS non logga');
  store = w.store;
  queue = queue.queueIfUnclassified(
    verdict: p,
    normalizedNumber: '+393330000001',
    rejectLink: 'reject-log#1',
  );
  _check(store.committedCount == 1, 'PASS non aggiunge righe');
  _check(queue.length == 1, 'PASS non accoda');

  // 3) Secondo REJECT senza restart: seconda riga + seconda pendenza.
  w = store.logDecision(
    verdict: r1,
    normalizedNumber: '+393330000031',
    templateRef: 'default-v1',
    at: t,
  );
  store = w.store;
  queue = queue.queueIfUnclassified(
    verdict: r1,
    normalizedNumber: '+393330000031',
    rejectLink: 'reject-log#1',
  );
  _check(store.committedCount == 2, 'attese 2 righe totali');
  _check(queue.length == 2, 'attese 2 pendenze');

  // 4) Classificazione: pendenze rimosse, righe restano.
  queue = queue.resolve('+393330000030');
  _check(queue.length == 1, 'dopo resolve resta 1 pendenza');
  queue = queue.resolve('00393330000031');
  _check(queue.isEmpty, 'pendenze rimosse anche in formato equivalente');
  _check(store.committedCount == 2, 'le righe restano dopo resolve');

  stdout.writeln('TP-1005 PASSED: reject-pass-reject integrato, 2 righe, pendenze rimosse');
}
