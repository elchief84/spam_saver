// Superficie /triage — vista SMS pendenti con esattamente 2 CTA
// (SRS-601/602/603/604). Label carattere-esatte, confirm + undo
// snackbar (RSK-108). Nessuna terza CTA primaria.

import 'package:flutter/material.dart';

import '../bridge/bridge_v1.dart';
import '../widgets/cta.dart';

class TriageScreen extends StatefulWidget {
  final CallGuardBridge bridge;

  const TriageScreen({super.key, required this.bridge});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  List<TriageItem> _items = const <TriageItem>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<TriageItem> items = await widget.bridge.getSmsTriage();
      if (!mounted) return;
      setState(() {
        _items = items.where((TriageItem e) => e.state == 'pending').toList();
        _error = null;
      });
    } on BridgeError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _classify(TriageItem item, String verdict) async {
    MembershipEffect? result;
    try {
      result = await widget.bridge.classifyNumber(
        normalizedNumber: item.normalizedNumber,
        verdict: verdict,
      );
      await _load();
    } on BridgeError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }
    if (!mounted) return;
    final MembershipEffect done = result;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(done.effect),
        action: SnackBarAction(
          label: 'Annulla',
          onPressed: _load,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Triage SMS')),
      body: _error != null
          ? Center(child: Text(_error!))
          : _items.isEmpty
              ? const Center(child: Text('Nessun SMS da classificare'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (BuildContext context, int i) {
                    final TriageItem item = _items[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(item.normalizedNumber),
                            Text(item.receivedAt),
                            Text(item.body),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                CtaButton(
                                  label: 'Accetta (whitelist)',
                                  description:
                                      'Aggiungi il numero in whitelist',
                                  onPressed: () =>
                                      _classify(item, 'whitelist'),
                                ),
                                const SizedBox(width: 8),
                                CtaButton(
                                  label: 'Rifiuta (blacklist)',
                                  description:
                                      'Aggiungi il numero in blacklist',
                                  onPressed: () =>
                                      _classify(item, 'blacklist'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
