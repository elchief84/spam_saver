// TP-301: decisione da solo snapshot, zero rete anche offline,
// entro 500ms p99. Eseguibile con: dart test/tp_301_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/screening_snapshot.dart';

void _fail(String msg) {
  stderr.writeln('TP-301 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

String _key(ScreeningVerdict v) =>
    '${v.action}|${v.origin}|${v.actuation}';

void main() {
  const snapshot = ScreeningSnapshot(
    contacts: ['+393330000001'],
    whitelist: ['+393330000010'],
    blacklist: ['+393330000002'],
  );

  // Stesso esito online e offline: la rete non conta.
  final probes = <String?>[
    '+393330000001',
    '+393330000002',
    '+393330000010',
    '+393330000030',
    '',
    null,
  ];
  for (final raw in probes) {
    final online = decideForNumber(
      raw: raw,
      presentation: Presentation.allowed,
      snapshot: snapshot,
      roleHeld: true,
    );
    final offline = decideForNumber(
      raw: raw,
      presentation: Presentation.allowed,
      snapshot: snapshot,
      roleHeld: true,
      offline: true,
    );
    _check(_key(online) == _key(offline),
        'esito diverso online/offline per "$raw"');
  }

  // Solo snapshot: congelare lo snapshot isola da mutazioni esterne.
  final external = <String>['+393330000030'];
  final frozen = ScreeningSnapshot(contacts: List.of(external));
  external.add('+393330000031');
  final v = decideForNumber(
    raw: '+393330000031',
    presentation: Presentation.allowed,
    snapshot: frozen,
    roleHeld: true,
  );
  _check(v.action == ScreeningAction.reject,
      'snapshot congelato non deve vedere mutazioni esterne');

  // Latenza p99 < 500ms su decisioni sincrone da snapshot.
  const runs = 500;
  final samples = <int>[];
  for (var i = 0; i < runs; i++) {
    final sw = Stopwatch()..start();
    decideForNumber(
      raw: '+393330000030',
      presentation: Presentation.allowed,
      snapshot: snapshot,
      roleHeld: true,
      offline: true,
    );
    sw.stop();
    samples.add(sw.elapsedMicroseconds);
  }
  samples.sort();
  final p99 = samples[(runs * 0.99).floor().clamp(0, runs - 1)];
  _check(meetsDecisionBudget(Duration(microseconds: p99)),
      'p99 ${p99}us oltre il budget di $maxDecisionMicros us');
  _check(p99 < maxDecisionMicros, 'p99 deve stare sotto 500ms');

  stdout.writeln('TP-301 PASSED: snapshot-only offline, p99 ${p99}us < 500ms');
}
