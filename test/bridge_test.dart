// Bridge v1 — round-trip + commit sincrono + errori da registry.
// Eseguibile con: flutter test test/bridge_test.dart
// Verifica SDS §6.2/§10.6: 15 metodi, codec canonico, envelope errore
// {code,message,action} mai stack/PII, classify effettiva post-commit.

import 'package:call_guard/bridge/bridge_v1.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(bridgeChannelName);
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      log.add(call);
      switch (call.method) {
        case BridgeMethods.getProtectionStatus:
          return <String, Object?>{
            'osSupported': true,
            'hasRole': true,
            'contacts': true,
            'phoneState': true,
            'sendSms': true,
            'readSms': true,
            'protectionActive': true,
          };
        case BridgeMethods.requestScreeningRole:
          return <String, Object?>{'requested': true};
        case BridgeMethods.getBlockedHistory:
          return <String, Object?>{
            'rows': <Map<String, Object?>>[
              <String, Object?>{
                'eventId': '3f6a9c2e-1b4d-4f8a-9c2e-7d1a5b3c9e0f',
                'normalizedNumber': '+393330000030',
                'displayNumber': '+39 333 000 0030',
                'calledAt': '2026-10-10T09:41:00.000Z',
                'outcome': 'rejected',
                'decisionOrigin': 'unknown',
                'actuation': 'disconnect',
                'smsStatus': 'sent',
                'smsReason': null,
                'retryCount': 0,
                'notes': '',
              },
            ],
            'total': 1,
          };
        case BridgeMethods.getSmsTriage:
          return <String, Object?>{
            'items': <Map<String, Object?>>[
              <String, Object?>{
                'providerMsgId': 'p1',
                'normalizedNumber': '+393330000030',
                'receivedAt': '2026-10-10T09:42:00.000Z',
                'body': 'Sono il dott. Rossi',
                'linkedEventId': '3f6a9c2e-1b4d-4f8a-9c2e-7d1a5b3c9e0f',
                'state': 'pending',
              },
            ],
          };
        case BridgeMethods.classifyNumber:
          final Map<Object?, Object?> args =
              (call.arguments as Map<Object?, Object?>?) ?? const {};
          final String verdict = args['verdict'] as String? ?? '';
          return <String, Object?>{
            'membership': verdict,
            'effect': verdict == 'whitelist'
                ? 'Da ora questo numero squillerà normalmente'
                : 'Da ora sarà sempre rifiutato',
          };
        case BridgeMethods.manageList:
          return <String, Object?>{
            'membership': 'blacklist',
            'effect': 'Da ora sarà sempre rifiutato',
          };
        case BridgeMethods.getNumberProfile:
          return <String, Object?>{
            'entry': <String, Object?>{
              'normalizedNumber': '+393330000030',
              'displayNumber': '+39 333 000 0030',
              'list': 'blacklist',
              'displayName': '',
              'notes': '',
              'category': '',
              'source': 'sms_classification',
              'dateAdded': '2026-10-10T09:41:00.000Z',
              'lastModified': '2026-10-10T09:43:00.000Z',
            },
            'historyRefs': <Map<String, Object?>>[],
          };
        case BridgeMethods.getSmsTemplate:
          return <String, Object?>{
            'text': 'Non posso rispondere ora. Ti richiamero il prima possibile.',
            'segments': 1,
            'encoding': 'GSM-7',
          };
        case BridgeMethods.setSmsTemplate:
          final Map<Object?, Object?> args =
              (call.arguments as Map<Object?, Object?>?) ?? const {};
          final String text = args['text'] as String? ?? '';
          if (text.trim().isEmpty) {
            throw PlatformException(
              code: 'VALIDATION_EMPTY_TEMPLATE',
              message: 'Il testo non può essere vuoto',
              details: <String, String>{'action': 'edit'},
            );
          }
          return <String, Object?>{
            'text': text,
            'segments': 1,
          };
        case BridgeMethods.restoreSmsTemplateDefault:
          return <String, Object?>{
            'text':
                'Non posso rispondere ora. Ti richiamero il prima possibile.',
          };
        case BridgeMethods.getBlacklistSmsFlag:
          return <String, Object?>{'enabled': false};
        case BridgeMethods.setBlacklistSmsFlag:
          final Map<Object?, Object?> args =
              (call.arguments as Map<Object?, Object?>?) ?? const {};
          return <String, Object?>{
            'enabled': args['enabled'] as bool? ?? false,
          };
        case BridgeMethods.retrySms:
          return <String, Object?>{
            'smsStatus': 'sent',
            'retryCount': 1,
          };
        case BridgeMethods.updateNotes:
          final Map<Object?, Object?> args =
              (call.arguments as Map<Object?, Object?>?) ?? const {};
          return <String, Object?>{
            'eventId': args['eventId'] as String? ?? '',
          };
        case BridgeMethods.ping:
          return <String, Object?>{'ok': true};
        default:
          throw PlatformException(
            code: 'INTERNAL_ERROR',
            message: 'Si è verificato un errore — riprova',
          );
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('canale versionato + 15 metodi dichiarati', () {
    expect(bridgeChannelName, 'call_guard/bridge_v1');
    expect(BridgeMethods.all.length, 15);
    expect(BridgeMethods.all.toSet().length, 15);
  });

  test('protection + role round-trip', () async {
    final CallGuardBridge bridge = CallGuardBridge();
    final ProtectionStatus status = await bridge.getProtectionStatus();
    expect(status.osSupported, isTrue);
    expect(status.hasRole, isTrue);
    expect(status.protectionActive, isTrue);
    expect(await bridge.requestScreeningRole(), isTrue);
  });

  test('history + triage round-trip con codec ISO/enum', () async {
    final CallGuardBridge bridge = CallGuardBridge();
    final List<BlockedRow> rows = await bridge.getBlockedHistory();
    expect(rows.length, 1);
    expect(rows.first.normalizedNumber, '+393330000030');
    expect(rows.first.decisionOrigin, 'unknown');
    expect(rows.first.retryCount, 0);
    final List<TriageItem> items = await bridge.getSmsTriage();
    expect(items.length, 1);
    expect(items.first.state, 'pending');
    expect(
      items.first.linkedEventId,
      '3f6a9c2e-1b4d-4f8a-9c2e-7d1a5b3c9e0f',
    );
  });

  test('classify sincrona effettiva con effect statement', () async {
    final CallGuardBridge bridge = CallGuardBridge();
    final MembershipEffect white = await bridge.classifyNumber(
      normalizedNumber: '+393330000030',
      verdict: 'whitelist',
    );
    expect(white.membership, 'whitelist');
    expect(white.effect.contains('squillerà'), isTrue);
    final MembershipEffect black = await bridge.classifyNumber(
      normalizedNumber: '+393330000030',
      verdict: 'blacklist',
    );
    expect(black.membership, 'blacklist');
    expect(black.effect.contains('rifiutato'), isTrue);
    // Il bridge attende il commit: il metodo channel è stato chiamato.
    expect(
      log.any((MethodCall c) => c.method == BridgeMethods.classifyNumber),
      isTrue,
    );
  });

  test('template + flag + retry + notes', () async {
    final CallGuardBridge bridge = CallGuardBridge();
    final Map<String, Object?> template = await bridge.getSmsTemplate();
    expect(template['segments'], 1);
    final Map<String, Object?> saved =
        await bridge.setSmsTemplate('Nuovo testo');
    expect(saved['text'], 'Nuovo testo');
    expect(await bridge.getBlacklistSmsFlag(), isFalse);
    expect(await bridge.setBlacklistSmsFlag(true), isTrue);
    final Map<String, Object?> retried =
        await bridge.retrySms('3f6a9c2e-1b4d-4f8a-9c2e-7d1a5b3c9e0f');
    expect(retried['smsStatus'], 'sent');
    expect(
      await bridge.updateNotes('evt-1', 'nota'),
      'evt-1',
    );
    expect(await bridge.ping(), isTrue);
    final TrustedEntryWire? profile =
        await bridge.getNumberProfile('+393330000030');
    expect(profile?.list, 'blacklist');
  });

  test('errori mappati da registry, mai stack/PII', () async {
    final CallGuardBridge bridge = CallGuardBridge();
    try {
      await bridge.setSmsTemplate('   ');
      fail('atteso BridgeError');
    } on BridgeError catch (e) {
      expect(e.code, 'VALIDATION_EMPTY_TEMPLATE');
      expect(e.message, 'Il testo non può essere vuoto');
      expect(e.toString().contains('StackTrace'), isFalse);
      expect(e.toString().contains('+39333'), isFalse);
    }
  });
}
