// Modulo domain: identita' numero, visibilita' e dialability SMS.
// Puro Dart, zero dipendenze piattaforma (vedi SDS SU-DOM-01-01).
// Implementa SRS-302, SRS-304, SRS-305.

/// Contesto di presentazione della piattaforma (da Call.Details).
enum Presentation {
  allowed,
  restricted,
  unknown,
  payphone,
}

/// Identificativo chiamante grezzo in ingresso.
class RawCallerId {
  final String? raw;
  final Presentation presentation;

  const RawCallerId({required this.raw, required this.presentation});
}

/// Valore numero canonico quando visibile.
class PhoneNumber {
  final String normalized;
  final String display;
  final bool dialableForSms;

  const PhoneNumber({
    required this.normalized,
    required this.display,
    required this.dialableForSms,
  });
}

/// Risultato classificazione: visibile, nascosto o vuoto.
abstract class PhoneNumberResult {
  const PhoneNumberResult();

  bool get isVisible => this is Visible;
  bool get isHidden => this is Hidden;
  bool get isEmpty => this is EmptyNumber;
}

/// Numero visibile con forma canonica e flag dialable.
class Visible extends PhoneNumberResult {
  final PhoneNumber number;

  const Visible(this.number);
}

/// Caller ID soppresso o non presentato.
class Hidden extends PhoneNumberResult {
  const Hidden();
}

/// Numero nullo o vuoto dopo trim.
class EmptyNumber extends PhoneNumberResult {
  const EmptyNumber();
}

final RegExp _alphaSender = RegExp(r'^[A-Za-z][A-Za-z0-9]*$');
final RegExp _shortCode = RegExp(r'^[0-9]{3,6}$');
final RegExp _dialable = RegExp(r'^\+?[0-9]{6,15}$');

const _separators = <String>[' ', '-', '.', '(', ')', '/'];

String _stripSeparators(String s) {
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (_separators.contains(c)) continue;
    buf.write(c);
  }
  return buf.toString();
}

/// Forma canonica: separatori rimossi, prefisso 00 convertito in +.
String normalizeNumber(String rawInput) {
  var s = _stripSeparators(rawInput.trim());
  if (s.startsWith('00')) {
    s = '+${s.substring(2)}';
  }
  return s;
}

String _digitsOnly(String s) {
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c >= 48 && c <= 57) buf.write(s[i]);
  }
  return buf.toString();
}

String _coreKey(String digits) {
  var d = digits;
  if (d.startsWith('0039')) {
    d = d.substring(4);
  } else if (d.startsWith('39') && d.length > 10 && d.length <= 13) {
    d = d.substring(2);
  }
  if (d.startsWith('0') && d.length > 1) {
    d = d.substring(1);
  }
  return d;
}

/// Chiave canonica per lookup liste/rubrica: collassa i formati
/// equivalenti (prefisso paese 39/0039/+, trunk nazionale 0,
/// separatori) nello stesso nucleo. Se non resta alcun nucleo
/// numerico (es. sender alfanumerici), ricade sulla forma
/// normalizzata cosi' voci distinte non collidono mai.
String canonicalNumberKey(String rawNumber) {
  final normalized = normalizeNumber(rawNumber);
  final core = _coreKey(_digitsOnly(normalized));
  if (core.isEmpty) return normalized;
  return core;
}

/// Due stringhe indicano lo stesso numero se i nuclei coincidono
/// dopo rimozione prefisso paese 39/0039 e trunk nazionale 0.
bool isSameNumber(String a, String b) {
  return _coreKey(_digitsOnly(normalizeNumber(a))) ==
      _coreKey(_digitsOnly(normalizeNumber(b)));
}

/// Alias di equivalenza per lookup rubrica/whitelist/blacklist.
bool areEquivalentNumbers(String a, String b) => isSameNumber(a, b);

/// Classificazione totale: mai throw, input non parsabile degrada
/// a non-dialable / Hidden / Empty.
PhoneNumberResult classifyCallerId(RawCallerId input) {
  if (input.presentation == Presentation.restricted ||
      input.presentation == Presentation.unknown) {
    return const Hidden();
  }
  final rawTrimmed = input.raw?.trim() ?? '';
  if (rawTrimmed.isEmpty) {
    return const EmptyNumber();
  }
  final s = _stripSeparators(rawTrimmed);
  if (s.isEmpty) {
    return const EmptyNumber();
  }
  final display = input.raw ?? '';
  if (_alphaSender.hasMatch(s)) {
    return Visible(
      PhoneNumber(normalized: s, display: display, dialableForSms: false),
    );
  }
  if (_shortCode.hasMatch(s)) {
    return Visible(
      PhoneNumber(normalized: s, display: display, dialableForSms: false),
    );
  }
  if (_dialable.hasMatch(s)) {
    return Visible(
      PhoneNumber(
        normalized: normalizeNumber(rawTrimmed),
        display: display,
        dialableForSms: true,
      ),
    );
  }
  return Visible(
    PhoneNumber(normalized: s, display: display, dialableForSms: false),
  );
}

/// Alias di classificazione con firma alternativa.
PhoneNumberResult parsePhoneNumber(String? raw,
        [Presentation presentation = Presentation.allowed]) =>
    classifyCallerId(RawCallerId(raw: raw, presentation: presentation));

/// True se l'input e' un numero visibile e componibile via SMS.
bool isSmsDialable(String? raw,
    {Presentation presentation = Presentation.allowed}) {
  final res =
      classifyCallerId(RawCallerId(raw: raw, presentation: presentation));
  if (res is Visible) return res.number.dialableForSms;
  return false;
}
