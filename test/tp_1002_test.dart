// TP-1002: Manifest senza INTERNET e allowBackup=false.
// Eseguibile con: dart test/tp_1002_test.dart
import 'dart:io';
import '../src/manifest/manifest_check.dart';

void _fail(String msg) {
  stderr.writeln('TP-1002 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  if (!File('src/fixtures/AndroidManifest.xml').existsSync()) {
    if (Directory('../src').existsSync()) Directory.current = '..';
  }
  final manifestFile = File('src/fixtures/AndroidManifest.xml');
  if (!manifestFile.existsSync()) _fail('fixture AndroidManifest.xml mancante');
  final xml = manifestFile.readAsStringSync();

  _check(!hasInternetPermission(xml), 'fixture contiene INTERNET');
  _check(isAllowBackupFalse(xml), 'fixture senza allowBackup=false');
  _check(isManifestCompliant(xml), 'fixture non conforme');
  _check(manifestViolations(xml).isEmpty, 'violazioni inattese in fixture');

  // Casi negativi: INTERNET deve essere rilevato.
  const withInternet = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <uses-permission android:name="android.permission.INTERNET"/>
  <application android:allowBackup="false"/>
</manifest>''';
  _check(hasInternetPermission(withInternet), 'INTERNET non rilevato');
  _check(!isManifestCompliant(withInternet), 'manifest con INTERNET marcato ok');

  // allowBackup true/mancante deve fallire.
  const backupTrue = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application android:allowBackup="true"/>
</manifest>''';
  _check(!isAllowBackupFalse(backupTrue), 'allowBackup=true accettato');
  _check(!isManifestCompliant(backupTrue), 'manifest senza allowBackup=false ok');
  _check(manifestViolations(backupTrue).contains('allowBackup=false mancante'),
      'violazione allowBackup non segnalata');

  stdout.writeln('TP-1002 PASSED: Manifest senza INTERNET, allowBackup=false');
}
