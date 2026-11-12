
import 'package:flutter/material.dart';

class PerfilUsuario extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const PerfilUsuario({
    super.key,
    required this.usuario,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = usuario['nombre'] ??
        usuario['nombreCompleto'] ??
        usuario['nombre_completo'] ??
        'Usuario';

    final correo = usuario['correo'] ??
        usuario['email'] ??
        'Correo no disponible';

    final rol = usuario['rol'] ??
        usuario['nombreRol'] ??
        usuario['nombre_rol'] ??
        'Estudiante';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 55,
                child: Icon(
                  Icons.person,
                  size: 65,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                nombre.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                rol.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Correo electrónico'),
                  subtitle: Text(correo.toString()),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver al inicio'),
                
              ),
              
const SizedBox(height: 12),
FilledButton.icon(
  onPressed: () {
    Navigator.of(context).popUntil(
      (route) => route.isFirst,
    );
  },
  icon: const Icon(Icons.logout),
  label: const Text('Cerrar sesión'),
),

            ],
          ),
        ),
      ),
    );
  }
}
