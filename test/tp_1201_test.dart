// TP-1201: cg-v1 con 15 metodi, round-trip del verdetto, classify
// sincrona effettiva, errori solo dal registry.
// Eseguibile con: dart test/tp_1201_test.dart
import 'dart:io';
import '../src/domain/call_guard_v1.dart';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/screening_snapshot.dart';

void _fail(String msg) {
  stderr.writeln('TP-1201 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  const guard = CallGuardV1(
    snapshot: ScreeningSnapshot(
      contacts: ['+393330000001'],
      whitelist: ['+393330000010'],
      blacklist: ['+393330000002'],
    ),
    roleHeld: true,
  );

  // Classify sincrona effettiva: visibile dialable vs nascosto/vuoto.
  final vis = guard.classify(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  _check(vis is Visible, 'classify: +393330000030 visibile');
  _check((vis as Visible).number.dialableForSms, 'classify: dialable effettivo');
  final hid = guard.classify(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.restricted));
  _check(hid is Hidden, 'classify: restricted nascosto');
  final empty = guard.classify(const RawCallerId(raw: '   ', presentation: Presentation.allowed));
  _check(empty is EmptyNumber, 'classify: vuoto effettivo');

  // Decisione effettiva da snapshot: contatto passa, blacklist rifiuta,
  // sconosciuto rifiuta (metodi 02/03 effettivi, non stub).
  final pass = guard.decideForNumber('+393330000001', Presentation.allowed);
  _check(pass.shouldPass && pass.origin == DecisionOrigin.contacts, 'contatto deve passare');
  final black = guard.decideForNumber('+393330000002', Presentation.allowed);
  _check(black.shouldReject && black.origin == DecisionOrigin.blacklist, 'blacklist deve rifiutare');
  final unknown = guard.decideForNumber('+393330000030', Presentation.allowed);
  _check(unknown.shouldReject && unknown.origin == DecisionOrigin.unknown, 'sconosciuto deve rifiutare');

  // Tutti i 15 metodi esercitati (conteggio cg-v1 = 15).
  final v = unknown;
  _check(guard.isPass(pass) && !guard.isPass(v), 'isPass effettivo');
  _check(guard.isReject(v) && !guard.isReject(pass), 'isReject effettivo');
  _check(guard.originOf(v) == DecisionOrigin.unknown, 'originOf effettivo');
  _check(guard.actuationOf(v) == ScreeningActuation.disconnect, 'actuationOf effettivo');
  _check(guard.shouldRing(pass) && !guard.shouldRing(v), 'shouldRing effettivo');
  _check(guard.shouldDisconnect(v) && !guard.shouldDisconnect(pass), 'shouldDisconnect effettivo');
  _check(guard.isUnknownReject(v) && !guard.isUnknownReject(black), 'isUnknownReject effettivo');
  _check(guard.isBlacklistReject(black) && !guard.isBlacklistReject(v), 'isBlacklistReject effettivo');
  _check(guard.decide(ScreeningFacts(
    visibility: vis,
    inContacts: false,
    inWhitelist: false,
    inBlacklist: true,
    roleHeld: true,
  )).origin == DecisionOrigin.blacklist, 'decide effettivo');

  // Round-trip: encode -> decode ricompone stesso verdetto.
  final cases = <ScreeningVerdict>[
    pass,
    black,
    unknown,
    const ScreeningVerdict(
        action: ScreeningAction.pass,
        origin: DecisionOrigin.noRole,
        actuation: ScreeningActuation.ring),
    const ScreeningVerdict(
        action: ScreeningAction.pass,
        origin: DecisionOrigin.anonymous,
        actuation: ScreeningActuation.ring),
  ];
  for (final c in cases) {
    final code = guard.encodeVerdict(c);
    final back = guard.decodeVerdict(code);
    _check(back.action == c.action && back.origin == c.origin && back.actuation == c.actuation,
        'round-trip fallito per $code');
  }
  // Round-trip helper sincrono classify->decide->encode->decode.
  final rt = cgRoundTrip(guard, '+393330000030', Presentation.allowed);
  _check(rt.shouldReject && rt.origin == DecisionOrigin.unknown, 'cgRoundTrip effettivo');

  // Errori solo dal registry: messaggi identici al registry, mai literal sparsi.
  _check(guard.errorFor(const RawCallerId(raw: ' ', presentation: Presentation.allowed)) == CgError.emptyNumber,
      'errorFor vuoto da registry');
  _check(guard.errorFor(const RawCallerId(raw: '+39333', presentation: Presentation.restricted)) == CgError.hiddenNumber,
      'errorFor nascosto da registry');
  _check(guard.errorFor(const RawCallerId(raw: '+393330000030', presentation: Presentation.allowed)) == CgError.none,
      'errorFor ok = none');
  _check(cgErrorMessage(CgError.emptyNumber) == cgErrorRegistry[CgError.emptyNumber],
      'messaggi effettivi dal registry');
  _check(cgErrorMessage(CgError.hiddenNumber) == cgErrorRegistry[CgError.hiddenNumber],
      'messaggi effettivi dal registry');
  const noRoleGuard = CallGuardV1(roleHeld: false);
  _check(noRoleGuard.errorFor(const RawCallerId(raw: '+393330000030', presentation: Presentation.allowed)) == CgError.missingRole,
      'ruolo mancante da registry');
  _check(cgErrorMessage(CgError.missingRole) == cgErrorRegistry[CgError.missingRole],
      'missingRole dal registry');
  // Codice corrotto: decodifica totale con fail-open, errore da registry.
  final corrupt = guard.decodeVerdict('corrotto');
  _check(corrupt.action == ScreeningAction.pass && corrupt.origin == DecisionOrigin.noRole,
      'corrupt deve dare fail-open');
  _check(cgErrorRegistry.containsKey(CgError.corruptCode), 'registry contiene corruptCode');

  // Describe usa il registry.
  final desc = guard.describe(pass);
  _check(desc.contains(cgErrorRegistry[CgError.none]!), 'describe usa il registry');

  stdout.writeln('TP-1201 PASSED: cg-v1 15 metodi round-trip classify sincrona errori da registry');
}
