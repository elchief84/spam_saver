// TP-603: pendenza di revisione rimossa dopo classificazione.
// Eseguibile con: dart test/tp_603_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/review_queue.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-603 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  final reject = decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: false,
    inWhitelist: false,
    inBlacklist: false,
    roleHeld: true,
  ));
  _check(reject.shouldReject, 'fixture deve essere REJECT unknown');

  var queue = const ReviewQueue().queueIfUnclassified(
    verdict: reject,
    normalizedNumber: '+393330000030',
    rejectLink: 'reject-log#0',
    at: DateTime.utc(2026, 5, 1, 10, 0, 0),
  );
  _check(queue.length == 1, 'attesa 1 pendenza');
  _check(queue.takeNext()?.numberKey == '+393330000030',
      'takeNext deve dare il numero accodato');

  // Dopo la classificazione la pendenza e' rimossa, anche in
  // formato equivalente (collasso via chiave canonica).
  queue = queue.resolve('0039 333 000 0030');
  _check(queue.isEmpty, 'resolve equivalente deve rimuovere la pendenza');
  _check(queue.length == 0, 'coda deve essere vuota dopo resolve');

  // Resolve di un numero assente: coda invariata. Numero vuoto: no-op.
  queue = const ReviewQueue().queueIfUnclassified(
    verdict: reject,
    normalizedNumber: '+393330000031',
    rejectLink: 'reject-log#1',
  );
  final same = queue.resolve('+393330000099');
  _check(same.length == 1, 'resolve assente deve lasciare 1 voce');
  queue = queue.resolve('');
  _check(queue.length == 1, 'resolve vuoto non deve rimuovere');

  // Remove e' alias di resolve; clear svuota tutto.
  queue = queue.remove('+393330000031');
  _check(queue.isEmpty, 'remove deve svuotare');
  queue = const ReviewQueue().queueIfUnclassified(
    verdict: reject,
    normalizedNumber: '+393330000031',
    rejectLink: 'reject-log#1',
  );
  queue = queue.clear();
  _check(queue.isEmpty, 'clear deve svuotare');

  stdout.writeln('TP-603 PASSED: pendenza rimossa dopo classificazione');
}
