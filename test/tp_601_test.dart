// TP-601: solo il numero rifiutato non classificato va in coda pending con link.
// Eseguibile con: dart test/tp_601_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/review_queue.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-601 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

ScreeningVerdict _verdict({
  required PhoneNumberResult vis,
  bool c = false,
  bool w = false,
  bool b = false,
  bool role = true,
}) {
  return decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: c,
    inWhitelist: w,
    inBlacklist: b,
    roleHeld: role,
  ));
}

void main() {
  final unknownVis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  final contactVis = classifyCallerId(const RawCallerId(
      raw: '+393330000001', presentation: Presentation.allowed));
  final hiddenVis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.restricted));

  // Rifiutato non classificato (unknown) => in coda con link.
  final unknownReject = _verdict(vis: unknownVis);
  _check(unknownReject.shouldReject && unknownReject.origin == DecisionOrigin.unknown,
      'fixture deve essere reject/unknown');
  var queue = const ReviewQueue();
  queue = queue.queueIfUnclassified(
    verdict: unknownReject,
    normalizedNumber: '+393330000030',
    rejectLink: 'reject-log#0',
    at: DateTime.utc(2026, 5, 1, 10, 0, 0),
  );
  _check(queue.length == 1, 'reject unknown deve accodare 1 voce, trovate ${queue.length}');
  _check(queue.pending.single.numberKey == '+393330000030',
      'voce deve portare il numero rifiutato');
  _check(queue.pending.single.rejectLink == 'reject-log#0',
      'voce deve portare il link, trovato ${queue.pending.single.rejectLink}');
  _check(queue.pending.single.rejectLink.contains('reject-log'),
      'link deve riferire il registro rifiutate');

  // REJECT blacklist (classificato) => mai in coda.
  final blackReject = _verdict(vis: unknownVis, b: true);
  _check(blackReject.origin == DecisionOrigin.blacklist, 'fixture blacklist attesa');
  final before = queue.length;
  queue = queue.queueIfUnclassified(
    verdict: blackReject,
    normalizedNumber: '+393330000002',
    rejectLink: 'reject-log#1',
  );
  _check(queue.length == before, 'reject blacklist non deve accodare');

  // PASS contatti => mai in coda.
  final contactPass = _verdict(vis: contactVis, c: true);
  _check(contactPass.shouldPass, 'contatto deve passare');
  queue = queue.queueIfUnclassified(
    verdict: contactPass,
    normalizedNumber: '+393330000001',
    rejectLink: 'reject-log#2',
  );
  _check(queue.length == before, 'PASS contatti non deve accodare');

  // PASS anonimo => mai in coda.
  final anonPass = _verdict(vis: hiddenVis);
  _check(anonPass.shouldPass, 'anonimo deve passare');
  queue = queue.queueIfUnclassified(
    verdict: anonPass,
    normalizedNumber: 'anon',
    rejectLink: 'reject-log#3',
  );
  _check(queue.length == before, 'PASS anonimo non deve accodare');

  // Numero vuoto o link vuoto => mai in coda.
  queue = queue.queueIfUnclassified(
    verdict: unknownReject,
    normalizedNumber: '',
    rejectLink: 'reject-log#4',
  );
  _check(queue.length == before, 'numero vuoto non deve accodare');
  queue = queue.queueIfUnclassified(
    verdict: unknownReject,
    normalizedNumber: '+393330000030',
    rejectLink: '',
  );
  _check(queue.length == before, 'link vuoto non deve accodare');

  _check(queue.length == 1, 'solo 1 voce attesa in coda, trovate ${queue.length}');
  stdout.writeln('TP-601 PASSED: solo reject unknown in pending con link');
}
