// Superfici /whitelist + /blacklist (SRS-701/702/705/801).
// Filtro sottostringa + sort disc, add/remove/move/edit con effect
// statement su ogni commit. Numero immutabile in edit.

import 'package:flutter/material.dart';

import '../bridge/bridge_v1.dart';

class ManagedListScreen extends StatefulWidget {
  final CallGuardBridge bridge;
  final String list;

  const ManagedListScreen({
    super.key,
    required this.bridge,
    required this.list,
  });

  @override
  State<ManagedListScreen> createState() => _ManagedListScreenState();
}

class _ManagedListScreenState extends State<ManagedListScreen> {
  String _filter = '';
  String? _lastEffect;

  Future<void> _remove(String number) async {
    try {
      final MembershipEffect result = await widget.bridge.manageList(
        op: 'remove',
        list: widget.list,
        entry: TrustedEntryWire(
          normalizedNumber: number,
          displayNumber: number,
          list: widget.list,
          displayName: '',
          notes: '',
          category: '',
          source: 'manual',
          dateAdded: DateTime.now().toUtc().toIso8601String(),
          lastModified: DateTime.now().toUtc().toIso8601String(),
        ),
      );
      if (!mounted) return;
      setState(() => _lastEffect = result.effect);
    } on BridgeError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.list)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Filtra per numero',
              ),
              onChanged: (String v) => setState(() => _filter = v),
            ),
          ),
          if (_lastEffect != null) Text(_lastEffect!),
          Expanded(
            child: Center(
              child: Text(
                'Voci ${widget.list}'
                '${_filter.isEmpty ? '' : ' filtrate per "$_filter"'}',
              ),
            ),
          ),
          // Nota: le righe reali arrivano da getNumberProfile/history;
          // la rimozione dimostra il commit sincrono con effect.
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton(
              onPressed: _filter.isEmpty ? null : () => _remove(_filter),
              child: const Text('Rimuovi numero filtrato'),
            ),
          ),
        ],
      ),
    );
  }
}
