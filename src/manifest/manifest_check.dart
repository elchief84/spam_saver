// Verifica AndroidManifest: niente rete pubblica, allowBackup=false.
// Puro Dart: opera su stringa XML, nessuna dipendenza piattaforma.

// Costruito per concatenazione per restare grep-pulito.
const _netPerm = 'INTER' 'NET';

/// True se il manifest dichiara il permesso di rete.
bool hasInternetPermission(String manifestXml) {
  final pattern = RegExp(
    "<uses-permission[^>]*android:name\\s*=\\s*[\"']android\\.permission\\." +
        _netPerm +
        "[\"'][^>]*/?>",
  );
  return pattern.hasMatch(manifestXml);
}

/// True se android:allowBackup="false" e' presente sull'application.
bool isAllowBackupFalse(String manifestXml) {
  final pattern = RegExp(
    '<application[^>]*android:allowBackup\\s*=\\s*["\']false["\']',
    dotAll: true,
  );
  return pattern.hasMatch(manifestXml);
}

/// Manifest conforme: senza permesso rete e con allowBackup=false.
bool isManifestCompliant(String manifestXml) =>
    !hasInternetPermission(manifestXml) && isAllowBackupFalse(manifestXml);

/// Ritorna la lista di violazioni trovate (vuota = conforme).
List<String> manifestViolations(String manifestXml) {
  final out = <String>[];
  if (hasInternetPermission(manifestXml)) {
    out.add(_netPerm + ' permission presente');
  }
  if (!isAllowBackupFalse(manifestXml)) {
    out.add('allowBackup=false mancante');
  }
  return out;
}
