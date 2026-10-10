// TP-102: sequenza reject-pass-reject senza restart sullo stesso store.
// Eseguibile con: dart test/tp_102_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/reject_store.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-102 FAILED: $msg');
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

ScreeningVerdict _pass() {
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
  _check(_reject().shouldReject, 'fixture reject attesa');
  _check(_pass().shouldPass, 'fixture pass attesa');

  // Stesso store, nessun restart: reject -> pass -> reject.
  var store = const RejectStore();
  var r = store.logDecision(
    verdict: _reject(),
    normalizedNumber: '+393330000030',
    templateRef: 'default-v1',
    at: t,
  );
  _check(r.outcome == StoreWriteOutcome.stored, 'primo REJECT deve loggare');
  store = r.store;
  _check(store.committedCount == 1, 'attesa 1 riga dopo primo REJECT');
  _check(store.pendingCount == 0, 'nessun pendente su store scrivibile');

  r = store.logDecision(
    verdict: _pass(),
    normalizedNumber: '+393330000001',
    templateRef: 'default-v1',
    at: t,
  );
  _check(r.outcome == StoreWriteOutcome.ignoredPass, 'PASS non deve loggare');
  store = r.store;
  _check(store.committedCount == 1, 'PASS non deve aggiungere righe');
  _check(store.pendingCount == 0, 'PASS non deve creare pendenti');

  r = store.logDecision(
    verdict: _reject(),
    normalizedNumber: '+393330000031',
    templateRef: 'default-v1',
    at: t,
  );
  _check(r.outcome == StoreWriteOutcome.stored, 'secondo REJECT deve loggare');
  store = r.store;
  _check(store.committedCount == 2, 'attese 2 righe dopo reject-pass-reject');
  _check(store.committed.entries[0].numberKey == '+393330000030',
      'prima riga attesa +393330000030');
  _check(store.committed.entries[1].numberKey == '+393330000031',
      'seconda riga attesa +393330000031');

  stdout.writeln('TP-102 PASSED: reject-pass-reject senza restart = 2 righe');
}
