// Modulo domain: gate puro di eleggibilita' SMS.
// Puro Dart, zero dipendenze piattaforma (vedi SDS SU-DOM-02-02).
// Implementa SRS-103, SRS-304, SRS-305, SRS-501, SRS-502.

import 'phone_number.dart';
import 'screening_decision.dart';

/// Motivo di skip dell'invio.
enum SmsSkipReason { blacklisted, nonDialable, hidden }

/// Fatti in ingresso al gate SMS.
class SmsFacts {
  final PhoneNumberResult visibility;
  final bool dialable;
  final DecisionOrigin decisionOrigin;
  final bool blacklistSmsEnabled;

  const SmsFacts({
    required this.visibility,
    required this.dialable,
    required this.decisionOrigin,
    required this.blacklistSmsEnabled,
  });
}

/// Risultato del gate: eleggibile o skippato con motivo.
abstract class SmsEligibilityResult {
  const SmsEligibilityResult();

  bool get isEligible => this is Eligible;
  bool get isSkipped => this is Skipped;
}

/// Invio consentito.
class Eligible extends SmsEligibilityResult {
  const Eligible();
}

/// Invio inibito con motivo di policy.
class Skipped extends SmsEligibilityResult {
  final SmsSkipReason reason;

  const Skipped(this.reason);
}

/// Gate puro. Ordine normativo:
/// hidden -> non-dialable -> blacklisted(flag OFF) -> eligible.
SmsEligibilityResult checkSmsEligibility(SmsFacts facts) {
  if (facts.visibility is Hidden || facts.visibility is EmptyNumber) {
    return const Skipped(SmsSkipReason.hidden);
  }
  if (!facts.dialable) {
    return const Skipped(SmsSkipReason.nonDialable);
  }
  if (facts.decisionOrigin == DecisionOrigin.blacklist &&
      !facts.blacklistSmsEnabled) {
    return const Skipped(SmsSkipReason.blacklisted);
  }
  return const Eligible();
}

/// Alias con nome alternativo per compatibilita'.
SmsEligibilityResult evaluateSmsEligibility(SmsFacts facts) =>
    checkSmsEligibility(facts);

/// Alias con nome alternativo per compatibilita'.
SmsEligibilityResult decideSmsEligibility(SmsFacts facts) =>
    checkSmsEligibility(facts);

/// Scorciatoia parametrica.
SmsEligibilityResult checkSmsEligibilityParams({
  required PhoneNumberResult visibility,
  required bool dialable,
  required DecisionOrigin decisionOrigin,
  required bool blacklistSmsEnabled,
}) {
  return checkSmsEligibility(
    SmsFacts(
      visibility: visibility,
      dialable: dialable,
      decisionOrigin: decisionOrigin,
      blacklistSmsEnabled: blacklistSmsEnabled,
    ),
  );
}

/// True se l'invio e' consentito per i fatti dati.
bool isSmsEligible(SmsFacts facts) =>
    checkSmsEligibility(facts) is Eligible;
