// TP-307: ruolo mancante prevale su tutto con singola azione pass/ring.
// Eseguibile con: dart test/tp_307_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-307 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  final vis = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));

  // Senza ruolo: una sola azione possibile (pass) con attuazione ring,
  // anche se il numero e' in blacklist o sconosciuto.
  final combos = <String, ScreeningFacts>{
    'sconosciuto': ScreeningFacts(
        visibility: vis,
        inContacts: false,
        inWhitelist: false,
        inBlacklist: false,
        roleHeld: false),
    'blacklist': ScreeningFacts(
        visibility: vis,
        inContacts: false,
        inWhitelist: false,
        inBlacklist: true,
        roleHeld: false),
    'contatti+blacklist': ScreeningFacts(
        visibility: vis,
        inContacts: true,
        inWhitelist: false,
        inBlacklist: true,
        roleHeld: false),
  };
  combos.forEach((label, facts) {
    final v = decideScreening(facts);
    _check(v.action == ScreeningAction.pass, '$label senza ruolo deve passare');
    _check(v.origin == DecisionOrigin.noRole, '$label origine deve essere noRole');
    _check(v.actuation == ScreeningActuation.ring,
        '$label attuazione deve essere ring');
    _check(v.shouldPass && !v.shouldReject, '$label singola azione pass');
  });

  // Con ruolo la blacklist torna a rifiutare: il ruolo e' il blocco.
  final held = decideScreening(ScreeningFacts(
    visibility: vis,
    inContacts: false,
    inWhitelist: false,
    inBlacklist: true,
    roleHeld: true,
  ));
  _check(held.shouldReject && held.origin == DecisionOrigin.blacklist,
      'con ruolo la blacklist deve rifiutare');

  stdout.writeln('TP-307 PASSED: ruolo mancante stato bloccante, singola azione pass/ring');
}
