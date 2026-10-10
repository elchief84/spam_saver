// Modulo domain: testo SMS predefinito e validazione pura.
// Puro Dart, zero dipendenze piattaforma.
// Il default e' confrontato carattere-esatto nei test; la validazione
// rifiuta il testo vuoto e oltre 480 caratteri (480 ammessi).

/// Limite massimo di caratteri per il testo SMS.
const int maxSmsChars = 480;

/// Testo predefinito. Confronto carattere-esatto in TP-503.
const String defaultSmsText =
    'Non posso rispondere ora. Ti richiamero il prima possibile.';

/// Motivo di rifiuto della validazione.
enum SmsTextInvalidReason { empty, tooLong }

/// Esito della validazione del testo SMS.
class SmsTextValidation {
  final bool valid;
  final SmsTextInvalidReason? reason;

  const SmsTextValidation.valid()
      : valid = true,
        reason = null;

  const SmsTextValidation.invalid(this.reason) : valid = false;
}

/// Valida il testo: rifiuta vuoto e oltre [maxSmsChars].
/// Funzione totale: mai throw.
SmsTextValidation validateSmsText(String text) {
  if (text.isEmpty) {
    return const SmsTextValidation.invalid(SmsTextInvalidReason.empty);
  }
  if (text.length > maxSmsChars) {
    return const SmsTextValidation.invalid(SmsTextInvalidReason.tooLong);
  }
  return const SmsTextValidation.valid();
}

/// True se il testo e' accettabile per l'invio.
bool isSmsTextValid(String text) => validateSmsText(text).valid;
