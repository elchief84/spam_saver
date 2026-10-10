// TP-201 + TP-201a: modulo domain senza import vietati,
// zero riferimenti telefonici nel Dart di produzione.
// Eseguibile con: dart test/tp_201_test.dart
import 'dart:io';
import '../src/guards/phone_scan.dart';

void _fail(String msg) {
  stderr.writeln('TP-201 FAILED: $msg');
  exit(1);
}

void main() {
  if (!File('src/domain/task.dart').existsSync()) {
    if (Directory('../src').existsSync()) Directory.current = '..';
  }

  final domainFiles = Directory('src/domain')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
  if (domainFiles.isEmpty) _fail('nessun file Dart in src/domain');

  for (final f in domainFiles) {
    final src = f.readAsStringSync();
    final badImports = findForbiddenDomainImports(src);
    if (badImports.isNotEmpty) {
      _fail('${f.path} contiene import vietati: $badImports');
    }
    // TP-201a: zero riferimenti telefonici nel domain.
    final tel = findPhoneViolations(src);
    if (tel.isNotEmpty) {
      _fail('${f.path} contiene riferimenti vietati: $tel');
    }
  }

  // Il detector deve riconoscere i casi vietati (prova runtime).
  final tWord = 'tele' 'com';
  if (containsPhoneReferences('void f() {}')) {
    _fail('falso positivo su codice pulito');
  }
  if (!containsPhoneReferences("import 'package:x/$tWord.dart';")) {
    _fail('mancata rilevazione telefonica');
  }
  final flWord = 'flut' 'ter';
  if (!hasForbiddenDomainImport(
      "import 'package:$flWord/material.dart';")) {
    _fail('mancata rilevazione import $flWord');
  }

  stdout.writeln(
      'TP-201 PASSED: ${domainFiles.length} file domain puliti, zero-tel');
}
