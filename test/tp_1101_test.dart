// TP-1101: revoca ruolo a caldo => fail-open (pass/ring/noRole) senza stallo.
// Eseguibile con: dart test/tp_1101_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/screening_snapshot.dart';

void _fail(String msg) {
  stderr.writeln('TP-1101 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  _check(vis is Visible, 'fixture sconosciuto deve essere Visible');

  // Sconosciuto disallow senza squillo (con ruolo): reject/disconnect.
  final unknownHeld = decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: false,
    inWhitelist: false,
    inBlacklist: false,
    roleHeld: true,
  ));
  _check(unknownHeld.action == ScreeningAction.reject, 'sconosciuto deve rifiutare');
  _check(unknownHeld.origin == DecisionOrigin.unknown, 'origine unknown');
  _check(unknownHeld.actuation == ScreeningActuation.disconnect, 'senza squillo: disconnect');
  _check(unknownHeld.actuation != ScreeningActuation.ring, 'sconosciuto mai ring');

  // Blacklist prevale su rubrica (con ruolo).
  final both = decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: true,
    inWhitelist: false,
    inBlacklist: true,
    roleHeld: true,
  ));
  _check(both.action == ScreeningAction.reject, 'blacklist+rubrica deve rifiutare');
  _check(both.origin == DecisionOrigin.blacklist, 'origine blacklist');
  _check(both.actuation == ScreeningActuation.disconnect, 'attuazione disconnect');

  // Revoca a caldo: da qualsiasi fatto precedente => fail-open immediato.
  final prior = [
    ScreeningFacts(visibility: vis, inContacts: false, inWhitelist: false, inBlacklist: false, roleHeld: true),
    ScreeningFacts(visibility: vis, inContacts: false, inWhitelist: false, inBlacklist: true, roleHeld: true),
    ScreeningFacts(visibility: vis, inContacts: true, inWhitelist: false, inBlacklist: true, roleHeld: true),
  ];
  for (var i = 0; i < prior.length; i++) {
    ScreeningVerdict v;
    try {
      v = reevaluateOnRoleChange(prior[i], false);
    } catch (e) {
      _fail('revoca $i ha lanciato: $e');
      rethrow;
    }
    _check(v.action == ScreeningAction.pass, 'revoca $i deve passare (fail-open)');
    _check(v.origin == DecisionOrigin.noRole, 'revoca $i origine noRole');
    _check(v.actuation == ScreeningActuation.ring, 'revoca $i attuazione ring');
    _check(isRoleRevokedFailOpen(v), 'revoca $i helper fail-open');
    _check(v.actuation != ScreeningActuation.disconnect, 'revoca $i mai disconnect');
    _check(v.actuation != ScreeningActuation.silenceFallback, 'revoca $i mai silenceFallback');
    final viaAlias = decideOnRoleRevoked(prior[i]);
    _check(viaAlias.action == ScreeningAction.pass && viaAlias.origin == DecisionOrigin.noRole,
        'revoca $i alias decideOnRoleRevoked fail-open');
    final viaHot = handleHotRoleRevocation(prior[i]);
    _check(viaHot.action == ScreeningAction.pass && viaHot.actuation == ScreeningActuation.ring,
        'revoca $i alias handleHotRoleRevocation fail-open');
  }

  // Senza stallo: rivalutazione sincrona entro budget 500ms, anche su snapshot.
  const runs = 300;
  final samples = <int>[];
  const snapshot = ScreeningSnapshot(blacklist: ['+393330000002']);
  for (var i = 0; i < runs; i++) {
    final facts = ScreeningFacts(
      visibility: vis,
      inContacts: false,
      inWhitelist: false,
      inBlacklist: snapshot.inBlacklist('+393330000030'),
      roleHeld: true,
    );
    final sw = Stopwatch()..start();
    final v = reevaluateOnRoleChange(facts, false);
    sw.stop();
    samples.add(sw.elapsedMicroseconds);
    _check(v.shouldPass, 'revoca a caldo sempre pass');
  }
  samples.sort();
  final p99 = samples[(runs * 0.99).floor().clamp(0, runs - 1)];
  _check(meetsDecisionBudget(Duration(microseconds: p99)), 'p99 revoca ${p99}us oltre budget');
  _check(p99 < maxDecisionMicros, 'p99 revoca sotto 500ms');

  // Ruolo ri-detenuto: torna a decidere normalmente (sconosciuto rifiuta).
  final reheld = reevaluateOnRoleChange(prior[0], true);
  _check(reheld.action == ScreeningAction.reject, 'ruolo ri-detenuto torna a rifiutare');

  stdout.writeln('TP-1101 PASSED: sconosciuto disallow/disconnect, blacklist>rubrica, revoca fail-open p99 ${p99}us');
}
