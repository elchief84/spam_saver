// TP-602: 2 CTA esatte visibili senza menu, con undo e content-description.
// Eseguibile con: dart test/tp_602_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/review_actions.dart';
import '../src/domain/review_queue.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-602 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  // 2 CTA esatte.
  _check(reviewCtas.length == 2, 'attese 2 CTA, trovate ${reviewCtas.length}');
  _check(reviewCtasAreExact(), 'CTA devono essere esatte');
  _check(reviewCtas[0].label == 'Metti in whitelist', 'prima CTA esatta');
  _check(reviewCtas[1].label == 'Metti in blacklist', 'seconda CTA esatta');

  // Visibili senza menu.
  _check(reviewCtasVisibleWithoutMenu(), 'CTA visibili senza menu');
  for (final c in reviewCtas) {
    _check(c.visibleWithoutMenu, 'CTA ${c.id} senza menu');
  }

  // Content-description non vuote e distinte.
  _check(reviewCtasHaveDescriptions(), 'content-description richieste');
  _check(reviewCtas[0].contentDescription.isNotEmpty, 'desc CTA1 vuota');
  _check(reviewCtas[1].contentDescription.isNotEmpty, 'desc CTA2 vuota');
  _check(reviewCtas[0].contentDescription != reviewCtas[1].contentDescription,
      'desc devono distinguersi');

  // Undo: resolve poi annulla e ritrova la pendenza.
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  final reject = decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: false,
    inWhitelist: false,
    inBlacklist: false,
    roleHeld: true,
  ));
  _check(reject.shouldReject, 'fixture deve essere REJECT');
  var history = ReviewHistory.start();
  final queued = history.current.queueIfUnclassified(
    verdict: reject,
    normalizedNumber: '+393330000030',
    rejectLink: 'reject-log#0',
  );
  history = history.push(queued);
  _check(history.current.length == 1, 'attesa 1 pendenza');
  final resolved = history.current.resolve('+393330000030');
  history = history.push(resolved);
  _check(history.current.isEmpty, 'dopo resolve coda vuota');
  _check(history.canUndo, 'undo deve essere disponibile');
  history = history.undo();
  _check(history.current.length == 1, 'undo deve ripristinare 1 pendenza');
  _check(history.current.takeNext()?.numberKey == '+393330000030',
      'undo ripristina il numero');

  // Undo senza passato: no-op.
  var empty = ReviewHistory.start();
  _check(!empty.canUndo, 'storia vuota senza undo');
  empty = empty.undo();
  _check(empty.current.isEmpty, 'undo vuoto resta vuoto');

  stdout.writeln('TP-602 PASSED: 2 CTA esatte senza menu, undo + desc');
}
