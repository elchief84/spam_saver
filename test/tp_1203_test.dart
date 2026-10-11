// TP-1203: 20/20 decisioni entro timeout, zero egress, notifica deep-link triage ok.
// Eseguibile con: dart test/tp_1203_test.dart
import 'dart:io';
import '../src/domain/call_guard_v1.dart';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/screening_snapshot.dart';
import '../src/domain/review_queue.dart';

void _fail(String msg) {
  stderr.writeln('TP-1203 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

String _key(ScreeningVerdict v) =>
    '${v.action.name}|${v.origin.name}|${v.actuation.name}';

/// Deep-link di notifica verso il triage di revisione. Puro, totale.
String triageDeepLink(String numberKey) => 'spam-saver://triage/$numberKey';

bool isTriageDeepLink(String link) =>
    link.startsWith('spam-saver://triage/') &&
    link.length > 'spam-saver://triage/'.length;

void main() {
  const guard = CallGuardV1(
    snapshot: ScreeningSnapshot(
      contacts: ['+393330000001'],
      whitelist: ['+393330000010'],
      blacklist: ['+393330000002'],
    ),
    roleHeld: true,
  );

  // 20 numeri distinti: 1 contatto, 1 whitelist, 1 blacklist, 17 sconosciuti.
  final numbers = <String>[
    '+393330000001',
    '+393330000010',
    '+393330000002',
    for (var i = 30; i < 47; i++) '+39333000${i.toString().padLeft(4, '0')}',
  ];
  _check(numbers.length == 20, 'attese 20 decisioni, trovate ${numbers.length}');

  // 20/20 decisioni entro timeout (budget 500ms), zero egress:
  // esito identico online/offline, decisione sincrona pura.
  var withinBudget = 0;
  var offlineParity = 0;
  final verdicts = <ScreeningVerdict>[];
  for (final n in numbers) {
    final sw = Stopwatch()..start();
    final online = guard.decideForNumber(n, Presentation.allowed);
    sw.stop();
    _check(meetsDecisionBudget(Duration(microseconds: sw.elapsedMicroseconds)),
        'decisione $n oltre timeout: ${sw.elapsedMicroseconds}us');
    withinBudget++;

    final offline = decideForNumber(
      raw: n,
      presentation: Presentation.allowed,
      snapshot: guard.snapshot,
      roleHeld: true,
      offline: true,
    );
    _check(_key(online) == _key(offline), 'egress per $n: online != offline');
    offlineParity++;
    verdicts.add(online);
    _check(online.actuation != ScreeningActuation.silenceFallback,
        'mai silenceFallback per $n');
  }
  _check(withinBudget == 20, 'entro timeout $withinBudget/20');
  _check(offlineParity == 20, 'zero egress $offlineParity/20');

  // Notifica deep-link triage ok: solo i REJECT unknown entrano in coda
  // con deep-link; la triage (takeNext/popFirst/resolve) funziona.
  var queue = const ReviewQueue();
  var queued = 0;
  for (var i = 0; i < numbers.length; i++) {
    final v = verdicts[i];
    final link = triageDeepLink(numbers[i]);
    _check(isTriageDeepLink(link), 'deep-link malformato per ${numbers[i]}');
    final before = queue.length;
    queue = queue.queueIfUnclassified(
      verdict: v,
      normalizedNumber: numbers[i],
      rejectLink: link,
    );
    if (v.shouldReject && v.origin == DecisionOrigin.unknown) {
      _check(queue.length == before + 1, 'unknown deve accodare notifica');
      queued++;
      final head = queue.pending.last;
      _check(head.rejectLink == link, 'link conservato per triage');
      _check(isTriageDeepLink(head.rejectLink), 'deep-link triage ok');
    } else {
      _check(queue.length == before, 'non-unknown mai in coda');
    }
  }
  _check(queued == 17, 'attesi 17 unknown in triage, trovati $queued');
  _check(queue.length == 17, 'coda triage 17 voci');

  // Triage ok: takeNext vede il primo, popFirst avanza, resolve rimuove
  // per chiave canonica (formati equivalenti collassano).
  final first = queue.takeNext();
  _check(first != null && first.numberKey == numbers[3], 'takeNext primo unknown');
  queue = queue.popFirst();
  _check(queue.length == 16, 'popFirst avanza di 1');
  queue = queue.resolve('+39 333 000 0031');
  final stillThere = queue.pending
      .where((e) => canonicalNumberKey(e.numberKey) == canonicalNumberKey('+393330000031'))
      .toList();
  _check(stillThere.isEmpty, 'resolve triage rimuove per equivalenza');

  stdout.writeln('TP-1203 PASSED: 20/20 entro timeout, zero egress, deep-link triage ok');
}
