// Superficie /history — cronologia rifiutate newest-first
// (SRS-401/402/403/801/704/902). Filtro sottostringa, retry manuale
// solo se failed + retry_count==0, promote 1-tap.

import 'package:flutter/material.dart';

import '../bridge/bridge_v1.dart';
import '../widgets/ledger_badge.dart';

class HistoryScreen extends StatefulWidget {
  final CallGuardBridge bridge;

  const HistoryScreen({super.key, required this.bridge});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _filter = '';
  List<BlockedRow> _rows = const <BlockedRow>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final List<BlockedRow> rows = await widget.bridge.getBlockedHistory(
        numberFilter: _filter.isEmpty ? null : _filter,
        limit: 200,
      );
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _error = null;
      });
    } on BridgeError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _retry(BlockedRow row) async {
    try {
      await widget.bridge.retrySms(row.eventId);
      await _load();
    } on BridgeError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<BlockedRow> visible = _filter.isEmpty
        ? _rows
        : _rows
            .where((BlockedRow r) => r.normalizedNumber.contains(_filter))
            .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Chiamate bloccate')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Filtra per numero',
              ),
              onChanged: (String v) {
                setState(() => _filter = v);
              },
            ),
          ),
          if (_error != null) Text(_error!),
          if (_rows.isEmpty && _error == null)
            const Expanded(
              child: Center(child: Text('Nessuna chiamata bloccata')),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (BuildContext context, int i) {
                  final BlockedRow row = visible[i];
                  final bool canRetry = row.smsStatus == 'failed' &&
                      row.retryCount == 0;
                  return ListTile(
                    title: Text(row.normalizedNumber),
                    subtitle: Text(
                      '${row.calledAt} · ${row.decisionOrigin} · note: ${row.notes}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        LedgerBadge(status: row.smsStatus),
                        if (canRetry)
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Riprova invio SMS',
                            onPressed: () => _retry(row),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/profile',
                      arguments: row.normalizedNumber,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
