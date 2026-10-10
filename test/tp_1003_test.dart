// TP-1003: gate PR — CI verde + test di comportamento, mai merge,
// solo task ready non blocked. Eseguibile con: dart test/tp_1003_test.dart
import 'dart:io';
import '../src/domain/gate.dart';
import '../src/domain/task.dart';

void _fail(String msg) {
  stderr.writeln('TP-1003 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  const ready = DevTask(id: 'T1', status: TaskStatus.ready);
  const blocked = DevTask(
      id: 'T2', status: TaskStatus.ready, blocked: true);
  const notReady = DevTask(id: 'T3', status: TaskStatus.done);

  // Pierino prende solo ready non blocked.
  _check(ready.isTakable, 'task ready dovrebbe essere takable');
  _check(!blocked.isTakable, 'task blocked non deve essere takable');
  _check(!notReady.isTakable, 'task non-ready non deve essere takable');

  // PR solo con CI verde + test.
  _check(
      canOpenPr(task: ready, ci: CiStatus.green, hasTests: true).allowed,
      'ready+CI verde+test dovrebbe aprire PR');
  _check(!canOpenPr(task: ready, ci: CiStatus.red, hasTests: true).allowed,
      'CI rossa deve bloccare PR');
  _check(
      !canOpenPr(task: ready, ci: CiStatus.green, hasTests: false).allowed,
      'senza test deve bloccare PR');
  _check(!canOpenPr(task: blocked, ci: CiStatus.green, hasTests: true).allowed,
      'blocked deve bloccare PR');
  _check(!canOpenPr(task: notReady, ci: CiStatus.green, hasTests: true).allowed,
      'non-ready deve bloccare PR');

  // Bug bloccante ferma, non bloccante no.
  _check(shouldStopForBug(blocking: true), 'bug bloccante deve fermare');
  _check(!shouldStopForBug(blocking: false), 'bug non bloccante non ferma');

  stdout.writeln('TP-1003 PASSED: gate PR CI-verde+test, ready-only');
}
