// Modulo domain: redazione PII e canarino di verifica.
// Puro Dart, zero dipendenze piattaforma.
// Politica: nessun numero in chiaro in logcat, file o crash. Ogni cifra
// e' sostituita con '*'. Il canarino non contiene cifre e non coincide
// mai con numeri reali o redatti. Funzioni totali: mai throw.

/// Canarino di verifica: marcatore mai presente nei dati reali.
const String piiCanary = 'CANARY-NEVER-MATCH-MARKER';

/// True se [candidate] e' esattamente il canarino.
bool isCanary(String candidate) => candidate == piiCanary;

/// Sostituisce ogni cifra con '*'. Totale.
String redactPii(String raw) {
  final buf = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final c = raw.codeUnitAt(i);
    if (c >= 48 && c <= 57) {
      buf.write('*');
    } else {
      buf.write(raw[i]);
    }
  }
  return buf.toString();
}

/// Redazione per logcat: zero cifre in chiaro.
String scrubForLogcat(String raw) => redactPii(raw);

/// Redazione per file: zero cifre in chiaro.
String scrubForFile(String raw) => redactPii(raw);

/// Redazione per crash report: zero cifre in chiaro.
String scrubForCrash(String raw) => redactPii(raw);

/// True se [s] contiene ancora cifre in chiaro (PII residua).
bool hasCleartextDigits(String s) {
  for (var i = 0; i < s.length; i++) {
    final c = s.codeUnitAt(i);
    if (c >= 48 && c <= 57) return true;
  }
  return false;
}

/// True se il redatto e' pulito: zero cifre e canarino mai incluso
/// come match di dati reali (il canarino resta riconoscibile solo
/// se cercato esplicitamente come marcatore).
bool isScrubbedClean(String scrubbed) => !hasCleartextDigits(scrubbed);
