// TP-704: senza ruolo una sola azione (pass/ring), mai disconnect ne'
// silenceFallback; su API28 il ruolo non e' detenibile quindi passa.
// Eseguibile con: dart test/tp_704_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-704 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  final hidden = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.restricted));

  // Su API <= 28 (incompatibile con lo screening gestito) il ruolo non
  // puo' essere detenuto: roleHeld=false forza lo stato bloccante.
  const api28 = 28;
  const roleHeldOnApi28 = false;
  _check(api28 < 29, 'API28 sotto la soglia di screening gestito');
  final v = decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: false,
    inWhitelist: false,
    inBlacklist: true,
    roleHeld: roleHeldOnApi28,
  ));
  _check(v.action == ScreeningAction.pass, 'API28 deve passare');
  _check(v.origin == DecisionOrigin.noRole, 'API28 origine noRole');
  _check(v.actuation == ScreeningActuation.ring, 'API28 attuazione ring');
  _check(v.actuation != ScreeningActuation.disconnect,
      'API28 mai disconnect');
  _check(v.actuation != ScreeningActuation.silenceFallback,
      'API28 mai silenceFallback');

  // Senza ruolo, mai silenceFallback in nessun caso: una sola azione.
  final cases = <PhoneNumberResult>[vis, hidden];
  for (final c in cases) {
    final r = decideScreening(ScreeningFacts(
      visibility: c,
      inContacts: true,
      inWhitelist: true,
      inBlacklist: true,
      roleHeld: false,
    ));
    _check(r.action == ScreeningAction.pass, 'no-role sempre pass');
    _check(r.actuation == ScreeningActuation.ring, 'no-role sempre ring');
    _check(r.actuation != ScreeningActuation.silenceFallback,
        'mai silenceFallback nel domain');
  }

  stdout.writeln('TP-704 PASSED: no-role singola azione pass/ring, API28 incompatibile passa');
}
