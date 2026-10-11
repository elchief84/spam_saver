// Entry point Flutter — presentation-only (SU-INF-07-01).
// Nessuna logica di screening qui: le decisioni arrivano dal nativo
// via CallGuardBridge (SRS-201). 6 superfici + dettaglio profilo.

import 'package:flutter/material.dart';

import 'bridge/bridge_v1.dart';
import 'screens/history.dart';
import 'screens/lists.dart';
import 'screens/profile.dart';
import 'screens/protection.dart';
import 'screens/settings_sms.dart';
import 'screens/triage.dart';

void main() {
  runApp(const CallGuardApp());
}

class CallGuardApp extends StatelessWidget {
  final CallGuardBridge? bridge;

  const CallGuardApp({super.key, this.bridge});

  @override
  Widget build(BuildContext context) {
    final CallGuardBridge effective = bridge ?? CallGuardBridge();
    return MaterialApp(
      title: 'Call Guard',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      initialRoute: '/protection',
      routes: <String, WidgetBuilder>{
        '/protection': (_) => ProtectionScreen(bridge: effective),
        '/history': (_) => HistoryScreen(bridge: effective),
        '/triage': (_) => TriageScreen(bridge: effective),
        '/whitelist': (_) =>
            ManagedListScreen(bridge: effective, list: 'whitelist'),
        '/blacklist': (_) =>
            ManagedListScreen(bridge: effective, list: 'blacklist'),
        '/settings/sms-text': (_) => SmsSettingsScreen(bridge: effective),
        '/settings/general': (_) => GeneralSettingsScreen(bridge: effective),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
