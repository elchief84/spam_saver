// Modulo domain: precedenza di screening pura.
// Puro Dart, zero dipendenze piattaforma (vedi SDS SU-DOM-02-01).
// Implementa SRS-302, SRS-303, SRS-304, SRS-306, SRS-703.

import 'phone_number.dart';

/// Azione di screening.
enum ScreeningAction { pass, reject }

/// Origine della decisione.
enum DecisionOrigin {
  contacts,
  whitelist,
  blacklist,
  unknown,
  anonymous,
  noRole,
}

/// Attuazione richiesta alla piattaforma.
enum ScreeningActuation { ring, disconnect, silenceFallback }

/// Fatti in ingresso alla funzione di decisione.
class ScreeningFacts {
  final PhoneNumberResult visibility;
  final bool inContacts;
  final bool inWhitelist;
  final bool inBlacklist;
  final bool roleHeld;

  const ScreeningFacts({
    required this.visibility,
    required this.inContacts,
    required this.inWhitelist,
    required this.inBlacklist,
    required this.roleHeld,
  });
}

/// Verdetto di screening.
class ScreeningVerdict {
  final ScreeningAction action;
  final DecisionOrigin origin;
  final ScreeningActuation actuation;

  const ScreeningVerdict({
    required this.action,
    required this.origin,
    required this.actuation,
  });

  bool get shouldReject => action == ScreeningAction.reject;
  bool get shouldPass => action == ScreeningAction.pass;
  bool get isReject => shouldReject;
}

/// Funzione totale di precedenza. Ordine normativo:
/// no-role -> anonimo-pass -> blacklist -> contacts/whitelist-pass
/// -> unknown-reject. Mai SILENCE_FALLBACK qui.
ScreeningVerdict decideScreening(ScreeningFacts facts) {
  if (!facts.roleHeld) {
    return const ScreeningVerdict(
      action: ScreeningAction.pass,
      origin: DecisionOrigin.noRole,
      actuation: ScreeningActuation.ring,
    );
  }
  if (facts.visibility is Hidden || facts.visibility is EmptyNumber) {
    return const ScreeningVerdict(
      action: ScreeningAction.pass,
      origin: DecisionOrigin.anonymous,
      actuation: ScreeningActuation.ring,
    );
  }
  if (facts.inBlacklist) {
    return const ScreeningVerdict(
      action: ScreeningAction.reject,
      origin: DecisionOrigin.blacklist,
      actuation: ScreeningActuation.disconnect,
    );
  }
  if (facts.inContacts) {
    return const ScreeningVerdict(
      action: ScreeningAction.pass,
      origin: DecisionOrigin.contacts,
      actuation: ScreeningActuation.ring,
    );
  }
  if (facts.inWhitelist) {
    return const ScreeningVerdict(
      action: ScreeningAction.pass,
      origin: DecisionOrigin.whitelist,
      actuation: ScreeningActuation.ring,
    );
  }
  return const ScreeningVerdict(
    action: ScreeningAction.reject,
    origin: DecisionOrigin.unknown,
    actuation: ScreeningActuation.disconnect,
  );
}

/// Alias con nome alternativo per compatibilita'.
ScreeningVerdict evaluateScreening(ScreeningFacts facts) =>
    decideScreening(facts);

/// Alias con nome alternativo per compatibilita'.
ScreeningVerdict screeningDecision(ScreeningFacts facts) =>
    decideScreening(facts);

/// Scorciatoia parametrica senza costruire [ScreeningFacts].
ScreeningVerdict decideScreeningParams({
  required PhoneNumberResult visibility,
  required bool inContacts,
  required bool inWhitelist,
  required bool inBlacklist,
  required bool roleHeld,
}) {
  return decideScreening(
    ScreeningFacts(
      visibility: visibility,
      inContacts: inContacts,
      inWhitelist: inWhitelist,
      inBlacklist: inBlacklist,
      roleHeld: roleHeld,
    ),
  );
}
