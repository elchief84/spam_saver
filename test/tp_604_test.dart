// TP-604: sequenza reject-pass-reject in coda senza restart.
// Eseguibile con: dart test/tp_604_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/review_queue.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-604 FAILED: $msg');
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
  final reject = _rejectUnknown();
  final pass = _passContact();
  _check(reject.shouldReject, 'fixture reject attesa');
  _check(pass.shouldPass, 'fixture pass attesa');

  // Stessa coda, nessun restart: reject accoda, pass e' no-op,
  // secondo reject accoda ancora.
  var queue = const ReviewQueue();
  queue = queue.queueIfUnclassified(
    verdict: reject,
    normalizedNumber: '+393330000030',
    rejectLink: 'reject-log#0',
  );
  _check(queue.length == 1, 'primo REJECT deve accodare');
  queue = queue.queueIfUnclassified(
    verdict: pass,
    normalizedNumber: '+393330000001',
    rejectLink: 'reject-log#1',
  );
  _check(queue.length == 1, 'PASS non deve accodare');
  queue = queue.queueIfUnclassified(
    verdict: reject,
    normalizedNumber: '+393330000031',
    rejectLink: 'reject-log#2',
  );
  _check(queue.length == 2, 'secondo REJECT deve accodare: attese 2 voci');

  // Consumo ordinato senza restart.
  _check(queue.takeNext()?.numberKey == '+393330000030',
      'takeNext deve dare la prima voce');
  queue = queue.popFirst();
  _check(queue.length == 1, 'popFirst deve lasciare 1 voce');
  _check(queue.takeNext()?.numberKey == '+393330000031',
      'ora takeNext deve dare la seconda voce');
  queue = queue.popFirst();
  _check(queue.isEmpty, 'coda svuotata dopo due pop');

  stdout.writeln('TP-604 PASSED: reject-pass-reject in coda senza restart = 2 voci');
}
