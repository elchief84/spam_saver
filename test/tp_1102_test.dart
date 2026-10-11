// TP-1102: 10/10 controlli squillo-reject conformi, eventi-invii 1a1 zero doppi.
// Eseguibile con: dart test/tp_1102_test.dart
import 'dart:io';
import '../src/domain/phone_number.dart';
import '../src/domain/screening_decision.dart';
import '../src/domain/reject_store.dart';
import '../src/domain/sms_dispatch.dart';
import '../src/domain/sms_eligibility.dart';

void _fail(String msg) {
  stderr.writeln('TP-1102 FAILED: $msg');
  exit(1);
}

void _check(bool cond, String msg) {
  if (!cond) _fail(msg);
}

class _Case {
  final String label;
  final ScreeningFacts facts;
  final ScreeningAction wantAction;
  final ScreeningActuation wantActuation;
  const _Case(this.label, this.facts, this.wantAction, this.wantActuation);
}

void main() {
  final visContact = classifyCallerId(const RawCallerId(
      raw: '+393330000001', presentation: Presentation.allowed));
  final visWhite = classifyCallerId(const RawCallerId(
      raw: '+393330000010', presentation: Presentation.allowed));
  final visBlack = classifyCallerId(const RawCallerId(
      raw: '+393330000002', presentation: Presentation.allowed));
  final visUnknown = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.allowed));
  final hid = classifyCallerId(const RawCallerId(
      raw: '+393330000030', presentation: Presentation.restricted));
  final empty = classifyCallerId(
      const RawCallerId(raw: '', presentation: Presentation.allowed));

  final cases = <_Case>[
    _Case('contatto->pass/ring', ScreeningFacts(visibility: visContact, inContacts: true, inWhitelist: false, inBlacklist: false, roleHeld: true), ScreeningAction.pass, ScreeningActuation.ring),
    _Case('whitelist->pass/ring', ScreeningFacts(visibility: visWhite, inContacts: false, inWhitelist: true, inBlacklist: false, roleHeld: true), ScreeningAction.pass, ScreeningActuation.ring),
    _Case('blacklist->reject/disconnect', ScreeningFacts(visibility: visBlack, inContacts: false, inWhitelist: false, inBlacklist: true, roleHeld: true), ScreeningAction.reject, ScreeningActuation.disconnect),
    _Case('blacklist+rubrica->reject/disconnect', ScreeningFacts(visibility: visBlack, inContacts: true, inWhitelist: false, inBlacklist: true, roleHeld: true), ScreeningAction.reject, ScreeningActuation.disconnect),
    _Case('sconosciuto->reject/disconnect', ScreeningFacts(visibility: visUnknown, inContacts: false, inWhitelist: false, inBlacklist: false, roleHeld: true), ScreeningAction.reject, ScreeningActuation.disconnect),
    _Case('nascosto->pass/ring', ScreeningFacts(visibility: hid, inContacts: false, inWhitelist: false, inBlacklist: false, roleHeld: true), ScreeningAction.pass, ScreeningActuation.ring),
    _Case('vuoto->pass/ring', ScreeningFacts(visibility: empty, inContacts: false, inWhitelist: false, inBlacklist: false, roleHeld: true), ScreeningAction.pass, ScreeningActuation.ring),
    _Case('noRole+contatto->pass/ring', ScreeningFacts(visibility: visContact, inContacts: true, inWhitelist: false, inBlacklist: false, roleHeld: false), ScreeningAction.pass, ScreeningActuation.ring),
    _Case('noRole+blacklist->pass/ring', ScreeningFacts(visibility: visBlack, inContacts: false, inWhitelist: false, inBlacklist: true, roleHeld: false), ScreeningAction.pass, ScreeningActuation.ring),
    _Case('noRole+sconosciuto->pass/ring', ScreeningFacts(visibility: visUnknown, inContacts: false, inWhitelist: false, inBlacklist: false, roleHeld: false), ScreeningAction.pass, ScreeningActuation.ring),
  ];
  _check(cases.length == 10, 'attesi 10 controlli, trovati ${cases.length}');

  // 10/10 controlli squillo-reject conformi: pass<=>ring, reject<=>disconnect,
  // mai silenceFallback.
  var conformi = 0;
  for (final c in cases) {
    final v = decideScreening(c.facts);
    _check(v.action == c.wantAction, '${c.label}: azione attesa ${c.wantAction}, trovata ${v.action}');
    _check(v.actuation == c.wantActuation, '${c.label}: attuazione attesa ${c.wantActuation}, trovata ${v.actuation}');
    _check(v.actuation != ScreeningActuation.silenceFallback, '${c.label}: mai silenceFallback');
    if (v.shouldPass) {
      _check(v.actuation == ScreeningActuation.ring, '${c.label}: pass deve squillare');
    } else {
      _check(v.actuation == ScreeningActuation.disconnect, '${c.label}: reject deve staccare senza squillo');
    }
    conformi++;
  }
  _check(conformi == 10, 'controlli conformi $conformi/10');

  // Eventi-invii 1a1 zero doppi: ogni REJECT = 1 riga + 1 invio; il
  // doppio event_id non re-invia; i PASS non creano righe.
  var store = const RejectStore();
  var dispatcher = const SmsDispatcher();
  var senderCalls = 0;
  void sender() {
    senderCalls++;
  }

  final t = DateTime.utc(2026, 5, 2, 10, 0, 0);
  var rejectSeen = 0;
  for (var i = 0; i < cases.length; i++) {
    final v = decideScreening(cases[i].facts);
    final before = store.committedCount;
    final res = store.logDecision(
      verdict: v,
      normalizedNumber: 'evt-$i',
      templateRef: 'default-v1',
      at: t,
    );
    store = res.store;
    if (v.shouldReject) {
      rejectSeen++;
      _check(res.outcome == StoreWriteOutcome.stored, '${cases[i].label}: REJECT deve loggare 1 riga');
      _check(store.committedCount == before + 1, '${cases[i].label}: 1 evento = 1 riga');
      final vis = classifyCallerId(const RawCallerId(
          raw: '+393330000030', presentation: Presentation.allowed));
      final dialable = (vis as Visible).number.dialableForSms;
      final facts = SmsFacts(
        visibility: vis,
        dialable: dialable,
        decisionOrigin: v.origin,
        blacklistSmsEnabled: true,
      );
      final eventId = 'evt-1102-$i';
      final first = dispatcher.dispatch(
        SmsDispatchEvent(eventId: eventId, facts: facts),
        sender,
      );
      dispatcher = first.dispatcher;
      _check(first.outcome == SmsSendOutcome.sent, '${cases[i].label}: 1 evento = 1 invio');
      final callsAfterFirst = senderCalls;
      final dup = dispatcher.dispatch(
        SmsDispatchEvent(eventId: eventId, facts: facts),
        sender,
      );
      dispatcher = dup.dispatcher;
      _check(dup.outcome == SmsSendOutcome.duplicateSuppressed, '${cases[i].label}: doppio soppresso');
      _check(senderCalls == callsAfterFirst, '${cases[i].label}: zero doppi invii');
    } else {
      _check(res.outcome == StoreWriteOutcome.ignoredPass, '${cases[i].label}: PASS senza righe');
      _check(store.committedCount == before, '${cases[i].label}: PASS 0 righe');
    }
  }
  _check(rejectSeen == 3, 'attesi 3 REJECT (blacklist, blacklist+rubrica, sconosciuto), trovati $rejectSeen');
  _check(store.committedCount == rejectSeen, 'eventi-invii 1a1: ${store.committedCount} righe per $rejectSeen REJECT');
  _check(dispatcher.senderCalls == rejectSeen, '1 invio per REJECT, zero doppi: ${dispatcher.senderCalls} invii');
  _check(senderCalls == rejectSeen, 'sender chiamato 1 volta per evento, zero doppi');

  stdout.writeln('TP-1102 PASSED: 10/10 squillo-reject conformi, eventi-invii 1a1 zero doppi');
}
