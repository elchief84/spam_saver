// Modulo domain: guard di versione cg-v1 con 15 metodi sincroni,
// round-trip del verdetto, classify effettiva e errori da registry.
// Puro Dart, zero dipendenze piattaforma.
// Proprieta':
// - 15 metodi pubblici su [CallGuardV1], tutti sincroni e totali
//   (mai throw, mai Future): classify e decisione effettive sul
//   snapshot, non stub;
// - round-trip: encodeVerdict/decodeVerdict e roundTrip ricompongono
//   lo stesso verdetto (azione/origine/attuazione);
// - errori solo dal registry [cgErrorRegistry]: nessun literal
//   d'errore sparso nei metodi, describe/errorFor leggono il registry.

import 'phone_number.dart';
import 'screening_decision.dart';
import 'screening_snapshot.dart';

/// Errori del guard, con messaggi centralizzati nel registry.
enum CgError {
  none,
  emptyNumber,
  hiddenNumber,
  missingRole,
  corruptCode,
}

/// Registry centrale dei messaggi d'errore cg-v1.
const Map<CgError, String> cgErrorRegistry = {
  CgError.none: 'ok',
  CgError.emptyNumber: 'numero vuoto: pass anonimo',
  CgError.hiddenNumber: 'numero nascosto: pass anonimo',
  CgError.missingRole: 'ruolo mancante: fail-open pass/ring',
  CgError.corruptCode: 'codice verdetto corrotto: fail-open pass/ring',
};

/// Messaggio d'errore dal registry. Totale.
String cgErrorMessage(CgError error) =>
    cgErrorRegistry[error] ?? cgErrorRegistry[CgError.corruptCode]!;

/// Guard cg-v1: 15 metodi pubblici, tutti sincroni e totali.
class CallGuardV1 {
  final ScreeningSnapshot snapshot;
  final bool roleHeld;

  const CallGuardV1({
    this.snapshot = const ScreeningSnapshot(),
    this.roleHeld = true,
  });

  /// 01: classificazione sincrona effettiva (degrada, mai throw).
  PhoneNumberResult classify(RawCallerId input) => classifyCallerId(input);

  /// 02: decisione sincrona effettiva sui fatti dati.
  ScreeningVerdict decide(ScreeningFacts facts) => decideScreening(facts);

  /// 03: decisione sincrona effettiva da numero grezzo + snapshot.
  ScreeningVerdict decideForNumber(String? raw, Presentation presentation) {
    return decideForNumberSnapshot(
      raw: raw,
      presentation: presentation,
      snapshot: snapshot,
      roleHeld: roleHeld,
    );
  }

  /// 04: true se il verdetto passa.
  bool isPass(ScreeningVerdict verdict) => verdict.shouldPass;

  /// 05: true se il verdetto rifiuta.
  bool isReject(ScreeningVerdict verdict) => verdict.shouldReject;

  /// 06: origine del verdetto.
  DecisionOrigin originOf(ScreeningVerdict verdict) => verdict.origin;

  /// 07: attuazione del verdetto.
  ScreeningActuation actuationOf(ScreeningVerdict verdict) =>
      verdict.actuation;

  /// 08: true se deve squillare (pass/ring).
  bool shouldRing(ScreeningVerdict verdict) =>
      verdict.shouldPass && verdict.actuation == ScreeningActuation.ring;

  /// 09: true se deve staccare (reject/disconnect).
  bool shouldDisconnect(ScreeningVerdict verdict) =>
      verdict.shouldReject &&
      verdict.actuation == ScreeningActuation.disconnect;

  /// 10: true se reject di numero non classificato (unknown).
  bool isUnknownReject(ScreeningVerdict verdict) =>
      verdict.shouldReject && verdict.origin == DecisionOrigin.unknown;

  /// 11: true se reject da lista bloccata.
  bool isBlacklistReject(ScreeningVerdict verdict) =>
      verdict.shouldReject && verdict.origin == DecisionOrigin.blacklist;

  /// 12: codifica round-trip del verdetto (azione|origine|attuazione).
  String encodeVerdict(ScreeningVerdict verdict) {
    return '${verdict.action.name}|${verdict.origin.name}|${verdict.actuation.name}';
  }

  /// 13: decodifica round-trip totale; codice corrotto -> fail-open
  /// con errore da registry, mai throw.
  ScreeningVerdict decodeVerdict(String code) {
    final parts = code.split('|');
    if (parts.length != 3) return roleRevokedFailOpenVerdict;
    final action = _actionByName(parts[0]);
    final origin = _originByName(parts[1]);
    final actuation = _actuationByName(parts[2]);
    if (action == null || origin == null || actuation == null) {
      return roleRevokedFailOpenVerdict;
    }
    return ScreeningVerdict(
        action: action, origin: origin, actuation: actuation);
  }

  /// 14: errore dal registry per l'input dato (mai literal sparsi).
  CgError errorFor(RawCallerId input) {
    if (!roleHeld) return CgError.missingRole;
    final res = classifyCallerId(input);
    if (res is EmptyNumber) return CgError.emptyNumber;
    if (res is Hidden) return CgError.hiddenNumber;
    return CgError.none;
  }

  /// 15: descrizione con messaggi effettivi dal registry.
  String describe(ScreeningVerdict verdict) {
    final err = verdict.origin == DecisionOrigin.noRole
        ? CgError.missingRole
        : CgError.none;
    return '${verdict.action.name}/${verdict.origin.name}/'
        '${verdict.actuation.name}:${cgErrorMessage(err)}';
  }
}

/// Helpers puri di supporto (fuori dal conteggio dei 15 metodi).

ScreeningVerdict decideForNumberSnapshot({
  required String? raw,
  required Presentation presentation,
  required ScreeningSnapshot snapshot,
  required bool roleHeld,
}) {
  final visibility =
      classifyCallerId(RawCallerId(raw: raw, presentation: presentation));
  final String? normalized =
      visibility is Visible ? visibility.number.normalized : null;
  return decideScreening(ScreeningFacts(
    visibility: visibility,
    inContacts:
        normalized != null && snapshot.inContacts(normalized),
    inWhitelist:
        normalized != null && snapshot.inWhitelist(normalized),
    inBlacklist:
        normalized != null && snapshot.inBlacklist(normalized),
    roleHeld: roleHeld,
  ));
}

/// Round-trip sincrono: classify -> decide -> encode -> decode.
/// Utile per i test di andata/ritorno.
ScreeningVerdict cgRoundTrip(
  CallGuardV1 guard,
  String? raw,
  Presentation presentation,
) {
  final v = guard.decideForNumber(raw, presentation);
  return guard.decodeVerdict(guard.encodeVerdict(v));
}

ScreeningAction? _actionByName(String name) {
  for (final v in ScreeningAction.values) {
    if (v.name == name) return v;
  }
  return null;
}

DecisionOrigin? _originByName(String name) {
  for (final v in DecisionOrigin.values) {
    if (v.name == name) return v;
  }
  return null;
}

ScreeningActuation? _actuationByName(String name) {
  for (final v in ScreeningActuation.values) {
    if (v.name == name) return v;
  }
  return null;
}
