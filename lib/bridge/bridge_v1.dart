// Bridge v1 — unico attraversamento native <-> Flutter (SDS §6, §10.6).
// Canale versionato `call_guard/bridge_v1`, metodi `cg/v1/*`.
// Regole: numeri sul wire sempre in forma canonica stringa, timestamp
// ISO8601 UTC, enum lowercase; errori come envelope
// {code, message, action}, mai stack/PII. Dart non implementa alcuna
// logica di screening: renderizza solo esiti committed dal nativo
// (SRS-201). `classify/manage/retry` ritornano dopo commit + snapshot.

import 'package:flutter/services.dart';

/// Nome canale versionato. Breaking futuri su `bridge_v2`.
const String bridgeChannelName = 'call_guard/bridge_v1';

/// Metodi `cg/v1/*` (15 voci normative SDS §6.2 + ping di versione).
abstract final class BridgeMethods {
  static const String getProtectionStatus = 'cg/v1/getProtectionStatus';
  static const String requestScreeningRole = 'cg/v1/requestScreeningRole';
  static const String getBlockedHistory = 'cg/v1/getBlockedHistory';
  static const String getSmsTriage = 'cg/v1/getSmsTriage';
  static const String classifyNumber = 'cg/v1/classifyNumber';
  static const String manageList = 'cg/v1/manageList';
  static const String getNumberProfile = 'cg/v1/getNumberProfile';
  static const String getSmsTemplate = 'cg/v1/getSmsTemplate';
  static const String setSmsTemplate = 'cg/v1/setSmsTemplate';
  static const String restoreSmsTemplateDefault =
      'cg/v1/restoreSmsTemplateDefault';
  static const String getBlacklistSmsFlag = 'cg/v1/getBlacklistSmsFlag';
  static const String setBlacklistSmsFlag = 'cg/v1/setBlacklistSmsFlag';
  static const String retrySms = 'cg/v1/retrySms';
  static const String updateNotes = 'cg/v1/updateNotes';
  static const String ping = 'cg/v1/ping';

  static const List<String> all = <String>[
    getProtectionStatus,
    requestScreeningRole,
    getBlockedHistory,
    getSmsTriage,
    classifyNumber,
    manageList,
    getNumberProfile,
    getSmsTemplate,
    setSmsTemplate,
    restoreSmsTemplateDefault,
    getBlacklistSmsFlag,
    setBlacklistSmsFlag,
    retrySms,
    updateNotes,
    ping,
  ];
}

/// Envelope errore canale. Messaggi statici, mai stack/PII (SRS-901).
class BridgeError implements Exception {
  final String code;
  final String message;
  final String action;

  const BridgeError({
    required this.code,
    required this.message,
    required this.action,
  });

  factory BridgeError.fromMap(Map<Object?, Object?> map) {
    return BridgeError(
      code: map['code'] as String? ?? 'INTERNAL_ERROR',
      message: map['message'] as String? ?? 'Si è verificato un errore — riprova',
      action: map['action'] as String? ?? 'none',
    );
  }

  Map<String, String> toMap() =>
      <String, String>{'code': code, 'message': message, 'action': action};

  @override
  String toString() => 'BridgeError($code)';
}

/// Stato protezione (SDS §6.3). `protectionActive = osSupported && hasRole`.
class ProtectionStatus {
  final bool osSupported;
  final bool hasRole;
  final bool contacts;
  final bool phoneState;
  final bool sendSms;
  final bool readSms;

  const ProtectionStatus({
    required this.osSupported,
    required this.hasRole,
    required this.contacts,
    required this.phoneState,
    required this.sendSms,
    required this.readSms,
  });

  bool get protectionActive => osSupported && hasRole;

  factory ProtectionStatus.fromMap(Map<Object?, Object?> map) {
    return ProtectionStatus(
      osSupported: map['osSupported'] as bool? ?? false,
      hasRole: map['hasRole'] as bool? ?? false,
      contacts: map['contacts'] as bool? ?? false,
      phoneState: map['phoneState'] as bool? ?? false,
      sendSms: map['sendSms'] as bool? ?? false,
      readSms: map['readSms'] as bool? ?? false,
    );
  }

  Map<String, bool> toMap() => <String, bool>{
        'osSupported': osSupported,
        'hasRole': hasRole,
        'contacts': contacts,
        'phoneState': phoneState,
        'sendSms': sendSms,
        'readSms': readSms,
        'protectionActive': protectionActive,
      };
}

/// Riga cronologia (SDS §6.3). Timestamp ISO8601, enum lowercase.
class BlockedRow {
  final String eventId;
  final String normalizedNumber;
  final String displayNumber;
  final String calledAt;
  final String outcome;
  final String decisionOrigin;
  final String actuation;
  final String smsStatus;
  final String? smsReason;
  final int retryCount;
  final String notes;

  const BlockedRow({
    required this.eventId,
    required this.normalizedNumber,
    required this.displayNumber,
    required this.calledAt,
    required this.outcome,
    required this.decisionOrigin,
    required this.actuation,
    required this.smsStatus,
    this.smsReason,
    required this.retryCount,
    required this.notes,
  });

  factory BlockedRow.fromMap(Map<Object?, Object?> map) {
    return BlockedRow(
      eventId: map['eventId'] as String? ?? '',
      normalizedNumber: map['normalizedNumber'] as String? ?? '',
      displayNumber: map['displayNumber'] as String? ?? '',
      calledAt: map['calledAt'] as String? ?? '',
      outcome: map['outcome'] as String? ?? 'rejected',
      decisionOrigin: map['decisionOrigin'] as String? ?? 'unknown',
      actuation: map['actuation'] as String? ?? 'disconnect',
      smsStatus: map['smsStatus'] as String? ?? 'pending',
      smsReason: map['smsReason'] as String?,
      retryCount: (map['retryCount'] as int?) ?? 0,
      notes: map['notes'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'eventId': eventId,
        'normalizedNumber': normalizedNumber,
        'displayNumber': displayNumber,
        'calledAt': calledAt,
        'outcome': outcome,
        'decisionOrigin': decisionOrigin,
        'actuation': actuation,
        'smsStatus': smsStatus,
        'smsReason': smsReason,
        'retryCount': retryCount,
        'notes': notes,
      };
}

/// Voce triage SMS (SDS §6.3).
class TriageItem {
  final String providerMsgId;
  final String normalizedNumber;
  final String receivedAt;
  final String body;
  final String? linkedEventId;
  final String state;

  const TriageItem({
    required this.providerMsgId,
    required this.normalizedNumber,
    required this.receivedAt,
    required this.body,
    this.linkedEventId,
    required this.state,
  });

  factory TriageItem.fromMap(Map<Object?, Object?> map) {
    return TriageItem(
      providerMsgId: map['providerMsgId'] as String? ?? '',
      normalizedNumber: map['normalizedNumber'] as String? ?? '',
      receivedAt: map['receivedAt'] as String? ?? '',
      body: map['body'] as String? ?? '',
      linkedEventId: map['linkedEventId'] as String?,
      state: map['state'] as String? ?? 'pending',
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        'providerMsgId': providerMsgId,
        'normalizedNumber': normalizedNumber,
        'receivedAt': receivedAt,
        'body': body,
        'linkedEventId': linkedEventId,
        'state': state,
      };
}

/// Entry liste sul wire (SDS §6.3).
class TrustedEntryWire {
  final String normalizedNumber;
  final String displayNumber;
  final String list;
  final String displayName;
  final String notes;
  final String category;
  final String source;
  final String dateAdded;
  final String lastModified;

  const TrustedEntryWire({
    required this.normalizedNumber,
    required this.displayNumber,
    required this.list,
    required this.displayName,
    required this.notes,
    required this.category,
    required this.source,
    required this.dateAdded,
    required this.lastModified,
  });

  factory TrustedEntryWire.fromMap(Map<Object?, Object?> map) {
    return TrustedEntryWire(
      normalizedNumber: map['normalizedNumber'] as String? ?? '',
      displayNumber: map['displayNumber'] as String? ?? '',
      list: map['list'] as String? ?? 'whitelist',
      displayName: map['displayName'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      category: map['category'] as String? ?? '',
      source: map['source'] as String? ?? 'manual',
      dateAdded: map['dateAdded'] as String? ?? '',
      lastModified: map['lastModified'] as String? ?? '',
    );
  }

  Map<String, String> toMap() => <String, String>{
        'normalizedNumber': normalizedNumber,
        'displayNumber': displayNumber,
        'list': list,
        'displayName': displayName,
        'notes': notes,
        'category': category,
        'source': source,
        'dateAdded': dateAdded,
        'lastModified': lastModified,
      };
}

/// Esito commit classificazione/gestione liste con effect statement.
class MembershipEffect {
  final String membership;
  final String effect;

  const MembershipEffect({required this.membership, required this.effect});

  factory MembershipEffect.fromMap(Map<Object?, Object?> map) {
    return MembershipEffect(
      membership: map['membership'] as String? ?? 'none',
      effect: map['effect'] as String? ?? '',
    );
  }
}

/// Bridge tipizzato verso il nativo. Ogni metodo ritorna solo dopo il
/// commit nativo + rebuild snapshot (SRS-307); gli errori di piattaforma
/// sono mappati a [BridgeError] dal registry §7, mai rilanciati grezzi.
class CallGuardBridge {
  final MethodChannel channel;

  CallGuardBridge({MethodChannel? channel})
      : channel = channel ?? const MethodChannel(bridgeChannelName);

  Future<T> _invoke<T>(
    String method,
    Map<String, Object?> args,
    T Function(Object? result) decode,
  ) async {
    try {
      final Object? result = await channel.invokeMethod<Object?>(
        method,
        args,
      );
      return decode(result);
    } on PlatformException catch (e) {
      throw BridgeError(
        code: e.code,
        message: e.message ?? 'Si è verificato un errore — riprova',
        action: (e.details is Map)
            ? (e.details as Map)['action'] as String? ?? 'none'
            : 'none',
      );
    } on BridgeError {
      rethrow;
    } catch (_) {
      throw const BridgeError(
        code: 'INTERNAL_ERROR',
        message: 'Si è verificato un errore — riprova',
        action: 'none',
      );
    }
  }

  static Map<String, Object?> _asStringMap(Object? result) {
    final Map<Object?, Object?> map = _asMap(result);
    return map.map((Object? k, Object? v) => MapEntry(k.toString(), v));
  }

  static Map<Object?, Object?> _asMap(Object? result) {
    if (result is Map<Object?, Object?>) return result;
    return const <Object?, Object?>{};
  }

  static List<Map<Object?, Object?>> _asMapList(Object? result) {
    if (result is List) {
      return result.whereType<Map<Object?, Object?>>().toList();
    }
    if (result is Map<Object?, Object?>) {
      final Object? rows = result['rows'] ?? result['items'];
      if (rows is List) {
        return rows.whereType<Map<Object?, Object?>>().toList();
      }
    }
    return const <Map<Object?, Object?>>[];
  }

  Future<ProtectionStatus> getProtectionStatus() {
    return _invoke<ProtectionStatus>(
      BridgeMethods.getProtectionStatus,
      const <String, Object?>{},
      (Object? r) => ProtectionStatus.fromMap(_asMap(r)),
    );
  }

  Future<bool> requestScreeningRole() {
    return _invoke<bool>(
      BridgeMethods.requestScreeningRole,
      const <String, Object?>{},
      (Object? r) => (_asMap(r)['requested'] as bool?) ?? false,
    );
  }

  Future<List<BlockedRow>> getBlockedHistory({
    String? numberFilter,
    int limit = 50,
    int offset = 0,
  }) {
    return _invoke<List<BlockedRow>>(
      BridgeMethods.getBlockedHistory,
      <String, Object?>{
        if (numberFilter != null) 'numberFilter': numberFilter,
        'limit': limit,
        'offset': offset,
      },
      (Object? r) =>
          _asMapList(r).map(BlockedRow.fromMap).toList(growable: false),
    );
  }

  Future<List<TriageItem>> getSmsTriage() {
    return _invoke<List<TriageItem>>(
      BridgeMethods.getSmsTriage,
      const <String, Object?>{},
      (Object? r) =>
          _asMapList(r).map(TriageItem.fromMap).toList(growable: false),
    );
  }

  Future<MembershipEffect> classifyNumber({
    required String normalizedNumber,
    required String verdict,
    String? displayName,
    String? notes,
    String? category,
  }) {
    return _invoke<MembershipEffect>(
      BridgeMethods.classifyNumber,
      <String, Object?>{
        'normalizedNumber': normalizedNumber,
        'verdict': verdict,
        if (displayName != null) 'displayName': displayName,
        if (notes != null) 'notes': notes,
        if (category != null) 'category': category,
      },
      (Object? r) => MembershipEffect.fromMap(_asMap(r)),
    );
  }

  Future<MembershipEffect> manageList({
    required String op,
    required String list,
    required TrustedEntryWire entry,
  }) {
    return _invoke<MembershipEffect>(
      BridgeMethods.manageList,
      <String, Object?>{
        'op': op,
        'list': list,
        'entry': entry.toMap(),
      },
      (Object? r) => MembershipEffect.fromMap(_asMap(r)),
    );
  }

  Future<TrustedEntryWire?> getNumberProfile(String normalizedNumber) {
    return _invoke<TrustedEntryWire?>(
      BridgeMethods.getNumberProfile,
      <String, Object?>{'normalizedNumber': normalizedNumber},
      (Object? r) {
        final Map<Object?, Object?> map = _asMap(r);
        final Object? entry = map['entry'];
        if (entry is Map<Object?, Object?>) {
          return TrustedEntryWire.fromMap(entry);
        }
        return null;
      },
    );
  }

  Future<Map<String, Object?>> getSmsTemplate() {
    return _invoke<Map<String, Object?>>(
      BridgeMethods.getSmsTemplate,
      const <String, Object?>{},
      _asStringMap,
    );
  }

  Future<Map<String, Object?>> setSmsTemplate(String text) {
    return _invoke<Map<String, Object?>>(
      BridgeMethods.setSmsTemplate,
      <String, Object?>{'text': text},
      _asStringMap,
    );
  }

  Future<Map<String, Object?>> restoreSmsTemplateDefault() {
    return _invoke<Map<String, Object?>>(
      BridgeMethods.restoreSmsTemplateDefault,
      const <String, Object?>{},
      _asStringMap,
    );
  }

  Future<bool> getBlacklistSmsFlag() {
    return _invoke<bool>(
      BridgeMethods.getBlacklistSmsFlag,
      const <String, Object?>{},
      (Object? r) => (_asMap(r)['enabled'] as bool?) ?? false,
    );
  }

  Future<bool> setBlacklistSmsFlag(bool enabled) {
    return _invoke<bool>(
      BridgeMethods.setBlacklistSmsFlag,
      <String, Object?>{'enabled': enabled},
      (Object? r) => (_asMap(r)['enabled'] as bool?) ?? false,
    );
  }

  Future<Map<String, Object?>> retrySms(String eventId) {
    return _invoke<Map<String, Object?>>(
      BridgeMethods.retrySms,
      <String, Object?>{'eventId': eventId},
      _asStringMap,
    );
  }

  Future<String> updateNotes(String eventId, String notes) {
    return _invoke<String>(
      BridgeMethods.updateNotes,
      <String, Object?>{'eventId': eventId, 'notes': notes},
      (Object? r) => (_asMap(r)['eventId'] as String?) ?? eventId,
    );
  }

  Future<bool> ping() {
    return _invoke<bool>(
      BridgeMethods.ping,
      const <String, Object?>{},
      (Object? r) => (_asMap(r)['ok'] as bool?) ?? true,
    );
  }
}
