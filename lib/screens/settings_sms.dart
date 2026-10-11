// Superfici /settings/sms-text + /settings/general
// (SRS-103/503). Editor con contatore segmenti + label encoding,
// field error, restore-default; toggle blacklist default OFF.

import 'package:flutter/material.dart';

import '../bridge/bridge_v1.dart';

class SmsSettingsScreen extends StatefulWidget {
  final CallGuardBridge bridge;

  const SmsSettingsScreen({super.key, required this.bridge});

  @override
  State<SmsSettingsScreen> createState() => _SmsSettingsScreenState();
}

class _SmsSettingsScreenState extends State<SmsSettingsScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _fieldError;
  String _segments = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final Map<String, Object?> current =
          await widget.bridge.getSmsTemplate();
      if (!mounted) return;
      setState(() {
        _controller.text = current['text'] as String? ?? '';
        _segments = '${current['segments'] ?? 1} segmento/i '
            '(${(current['encoding'] as String?) ?? 'GSM-7'})';
        _fieldError = null;
      });
    } on BridgeError catch (e) {
      if (!mounted) return;
      setState(() => _fieldError = e.message);
    }
  }

  Future<void> _save() async {
    try {
      final Map<String, Object?> saved =
          await widget.bridge.setSmsTemplate(_controller.text);
      if (!mounted) return;
      setState(() {
        _fieldError = null;
        _segments = '${saved['segments'] ?? 1} segmento/i';
      });
    } on BridgeError catch (e) {
      if (!mounted) return;
      setState(() => _fieldError = e.message);
    }
  }

  Future<void> _restore() async {
    await widget.bridge.restoreSmsTemplateDefault();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Testo SMS automatico')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Testo risposta',
              errorText: _fieldError,
            ),
          ),
          Text(_segments),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              FilledButton(onPressed: _save, child: const Text('Salva')),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _restore,
                child: const Text('Ripristina default'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GeneralSettingsScreen extends StatefulWidget {
  final CallGuardBridge bridge;

  const GeneralSettingsScreen({super.key, required this.bridge});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bool enabled = await widget.bridge.getBlacklistSmsFlag();
    if (!mounted) return;
    setState(() => _enabled = enabled);
  }

  Future<void> _set(bool value) async {
    final bool saved = await widget.bridge.setBlacklistSmsFlag(value);
    if (!mounted) return;
    setState(() => _enabled = saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni generali')),
      body: SwitchListTile(
        title: const Text('Invia SMS ai numeri in blacklist'),
        subtitle: const Text('Default disattivato per evitare spam'),
        value: _enabled,
        onChanged: _set,
      ),
    );
  }
}
