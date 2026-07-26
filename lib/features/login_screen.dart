import 'package:flutter/material.dart';

import '../shared/widgets/ordo_app_bar.dart';

class LoginPlaceholderScreen extends StatelessWidget {
  const LoginPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: OrdoAppBar(title: 'Iniciar sesión'),
      body: Center(child: Text('Pantalla de inicio de sesión pendiente')),
    );
  }
}
