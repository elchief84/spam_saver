// Superficie /protection — onboarding blocco-ruolo (SRS-202/1005).
// Banner bloccante + singola azione role-request; mai dichiara
// protezione senza ruolo.

import 'package:flutter/material.dart';

import '../bridge/bridge_v1.dart';

class ProtectionScreen extends StatefulWidget {
  final CallGuardBridge bridge;

  const ProtectionScreen({super.key, required this.bridge});

  @override
  State<ProtectionScreen> createState() => _ProtectionScreenState();
}

class _ProtectionScreenState extends State<ProtectionScreen> {
  ProtectionStatus? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final ProtectionStatus status =
          await widget.bridge.getProtectionStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        _error = null;
      });
    } on BridgeError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _requestRole() async {
    await widget.bridge.requestScreeningRole();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ProtectionStatus? status = _status;
    return Scaffold(
      appBar: AppBar(title: const Text('Protezione')),
      body: _error != null
          ? Center(child: Text(_error!))
          : status == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: <Widget>[
                    if (!status.osSupported)
                      const ListTile(
                        title: Text(
                          'Dispositivo non compatibile — richiesta Android 10+',
                        ),
                      )
                    else if (!status.hasRole)
                      ListTile(
                        title: const Text(
                          'Protezione non attiva — tocca per assegnare il ruolo',
                        ),
                        trailing: FilledButton(
                          onPressed: _requestRole,
                          child: const Text('Assegna ruolo'),
                        ),
                      )
                    else
                      const ListTile(title: Text('Protezione attiva')),
                    ListTile(
                      title: const Text('Stato permessi'),
                      subtitle: Text(
                        'rubrica=${status.contacts} sms-invio=${status.sendSms} '
                        'sms-lettura=${status.readSms}',
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/history'),
                          child: const Text('Cronologia'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/triage'),
                          child: const Text('Triage'),
                        ),
                      ],
                    ),
                  ],
                ),
    );
  }
}
