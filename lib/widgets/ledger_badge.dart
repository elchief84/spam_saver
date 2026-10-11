// Widget ledger badge — stato invio SMS sulla riga cronologia
// (SRS-402): pending/sent/failed/skipped, mai corpo messaggio.

import 'package:flutter/material.dart';

class LedgerBadge extends StatelessWidget {
  final String status;

  const LedgerBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(status));
  }
}
