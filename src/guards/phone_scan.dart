// TP-201a: zero chiamate telefoniche nel Dart di produzione.
// Scanner puro Dart: rileva riferimenti vietati nel codice Dart.
// Nota: i literal vietati sono costruiti per concatenazione cosi'
// il detector stesso resta grep-pulito per controlli ingenui.

// pezzo base spezzato per non contenere il literal nel sorgente.
const _t = 'tele' 'com';

/// Pattern vietati nel codice Dart (case-insensitive dove ha senso).
final List<RegExp> forbiddenPhonePatterns = [
  RegExp(_t, caseSensitive: false),
  RegExp('Tele' 'comManager'),
  RegExp('ConnectionService'),
  RegExp('PhoneAccount'),
  RegExp('CALL_PHONE'),
  RegExp('READ_PHONE_STATE'),
  RegExp('READ_CALL_LOG'),
  RegExp('android.' + _t),
];

/// Sottostringa per gli import vietati nel modulo domain.
const _fl = 'flut' 'ter';

/// Pattern di import vietati nel modulo domain.
final List<RegExp> forbiddenDomainImports = [
  RegExp("import\\s+['\"]package:" + _fl),
  RegExp("import\\s+['\"]package:android"),
  RegExp('package:' + _fl + '/'),
  RegExp('android.' + _t),
  RegExp('Tele' 'comManager'),
];

/// True se il sorgente contiene riferimenti vietati.
bool containsPhoneReferences(String dartSource) =>
    findPhoneViolations(dartSource).isNotEmpty;

/// Lista dei pattern vietati trovati nel sorgente.
List<String> findPhoneViolations(String dartSource) {
  final out = <String>[];
  for (final p in forbiddenPhonePatterns) {
    if (p.hasMatch(dartSource)) {
      out.add(p.pattern);
    }
  }
  return out;
}

/// True se il sorgente ha import vietati per il domain.
bool hasForbiddenDomainImport(String dartSource) =>
    findForbiddenDomainImports(dartSource).isNotEmpty;

/// Lista dei pattern di import vietati trovati.
List<String> findForbiddenDomainImports(String dartSource) {
  final out = <String>[];
  for (final p in forbiddenDomainImports) {
    if (p.hasMatch(dartSource)) {
      out.add(p.pattern);
    }
  }
  return out;
}
