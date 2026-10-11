// Widget CTA — le 2 azioni triage sempre visibili senza menu,
// con content-description distinte (SRS-602, RSK-108).

import 'package:flutter/material.dart';

class CtaButton extends StatelessWidget {
  final String label;
  final String description;
  final VoidCallback onPressed;

  const CtaButton({
    super.key,
    required this.label,
    required this.description,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: Semantics(
        button: true,
        label: description,
        child: Text(label),
      ),
    );
  }
}
