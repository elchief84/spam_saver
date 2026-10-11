// Modulo domain: profilo con 3 campi modificabili e persistiti.
// Puro Dart, zero dipendenze piattaforma.
// I 3 campi sono displayName, smsText e blacklistSmsEnabled.
// Persistenza sincrona su mappa di stringhe con round-trip totale:
// mai throw, input corrotto degrada ai default. Funzioni totali.

import 'sms_template.dart';

/// Profilo con esattamente 3 campi.
class UserProfile {
  final String displayName;
  final String smsText;
  final bool blacklistSmsEnabled;

  const UserProfile({
    required this.displayName,
    required this.smsText,
    required this.blacklistSmsEnabled,
  });

  /// Default: nome vuoto, SMS di default, invio blacklist attivo.
  factory UserProfile.defaults() =>
      const UserProfile(
        displayName: '',
        smsText: defaultSmsText,
        blacklistSmsEnabled: true,
      );

  /// Modifica parziale: restituisce un nuovo profilo.
  UserProfile edit({
    String? displayName,
    String? smsText,
    bool? blacklistSmsEnabled,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      smsText: smsText ?? this.smsText,
      blacklistSmsEnabled:
          blacklistSmsEnabled ?? this.blacklistSmsEnabled,
    );
  }

  /// True se il testo SMS del profilo e' valido per l'invio.
  bool get isSmsTextValid => isSmsTextValidFn(smsText);

  /// Serializzazione su mappa di stringhe. Totale.
  Map<String, String> toMap() => <String, String>{
        'displayName': displayName,
        'smsText': smsText,
        'blacklistSmsEnabled': blacklistSmsEnabled ? '1' : '0',
      };

  /// Deserializzazione totale: mai throw, corrotto -> default.
  static UserProfile fromMap(Map<String, String> map) {
    try {
      final name = map['displayName'] ?? '';
      final text = (map['smsText'] ?? '').isEmpty
          ? defaultSmsText
          : map['smsText']!;
      final flag = (map['blacklistSmsEnabled'] ?? '1') == '1';
      return UserProfile(
        displayName: name,
        smsText: text,
        blacklistSmsEnabled: flag,
      );
    } catch (_) {
      return UserProfile.defaults();
    }
  }
}

/// Alias per validazione senza collisioni di nome.
bool isSmsTextValidFn(String text) => isSmsTextValid(text);
