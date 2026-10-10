// TP-1001: anonimi e contatti in PASS non creano righe.
// Solo i REJECT sono registrati. Eseguibile con: dart test/tp_1001_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/reject_store.dart';
import '../src/domain/screening_decision.dart';

void _fail(String msg) {
  stderr.writeln('TP-1001 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

void main() {
  var store = const RejectStore();
  final t = DateTime.utc(2026, 5, 1, 10, 0, 0);

  // Casi anonimi: tutti PASS per politica, nessuna riga.
  final anonCases = <PhoneNumberResult>[
    classifyCallerId(const RawCallerId(
        raw: '+393330000030', presentation: Presentation.restricted)),
    classifyCallerId(const RawCallerId(
        raw: '+393330000030', presentation: Presentation.unknown)),
    classifyCallerId(
        const RawCallerId(raw: '', presentation: Presentation.allowed)),
    classifyCallerId(
        const RawCallerId(raw: null, presentation: Presentation.allowed)),
  ];
  for (var i = 0; i < anonCases.length; i++) {
    final verdict = decideScreening(ScreeningFacts(
      visibility: anonCases[i],
      inContacts: false,
      inWhitelist: false,
      inBlacklist: false,
      roleHeld: true,
    ));
    _check(verdict.action == ScreeningAction.pass, 'anonimo $i deve passare');
    final res = store.logDecision(
      verdict: verdict,
      normalizedNumber: 'anon-$i',
      templateRef: 'default-v1',
      at: t,
    );
    _check(res.outcome == StoreWriteOutcome.ignoredPass,
        'anonimo $i PASS non deve loggare');
    store = res.store;
    _check(store.committedCount == 0, 'anonimo $i ha creato righe');
    _check(store.pendingCount == 0, 'anonimo $i ha creato pendenti');
  }

  // Contatto noto in PASS: nessuna riga.
  final contact = classifyCallerId(const RawCallerId(
      raw: '+393330000001', presentation: Presentation.allowed));
  final passVerdict = decideScreening(ScreeningFacts(
    visibility: contact,
    inContacts: true,
    inWhitelist: false,
    inBlacklist: false,
    roleHeld: true,
  ));
  _check(passVerdict.action == ScreeningAction.pass, 'contatto deve passare');
  final passRes = store.logDecision(
    verdict: passVerdict,
    normalizedNumber: '+393330000001',
    templateRef: 'default-v1',
    at: t,
  );
  _check(passRes.outcome == StoreWriteOutcome.ignoredPass,
      'contatto PASS non deve loggare');
  store = passRes.store;
  _check(store.committedCount == 0, 'contatto PASS ha creato righe');

  // Controllo: uno sconosciuto REJECT crea esattamente una riga.
  final unknown = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  final rejectVerdict = decideScreening(ScreeningFacts(
    visibility: unknown,
    inContacts: false,
    inWhitelist: false,
    inBlacklist: false,
    roleHeld: true,
  ));
  _check(
      rejectVerdict.action == ScreeningAction.reject, 'sconosciuto deve rifiutare');
  final rejRes = store.logDecision(
    verdict: rejectVerdict,
    normalizedNumber: '+393330000030',
    templateRef: 'default-v1',
    at: t,
  );
  _check(rejRes.outcome == StoreWriteOutcome.stored, 'REJECT deve loggare');
  store = rejRes.store;
  _check(store.committedCount == 1, 'attesa 1 sola riga dal REJECT');

  stdout.writeln('TP-1001 PASSED: 4 anonimi + 1 contatto PASS senza righe, 1 REJECT = 1 riga');
}
