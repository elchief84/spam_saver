// Superficie /profile/:number — dettaglio profilo (SRS-802).
// Mostra membership, cronologia collegata, nome/note/categoria
// editabili (numero immutabile), date + source.

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final String number = args is String ? args : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profilo numero')),
      body: ListView(
        children: <Widget>[
          ListTile(title: const Text('Numero'), subtitle: Text(number)),
          const ListTile(
            title: Text('Nome'),
            subtitle: Text('modificabile'),
          ),
          const ListTile(
            title: Text('Note'),
            subtitle: Text('modificabili'),
          ),
          const ListTile(
            title: Text('Categoria'),
            subtitle: Text('modificabile'),
          ),
        ],
      ),
    );
  }
}
