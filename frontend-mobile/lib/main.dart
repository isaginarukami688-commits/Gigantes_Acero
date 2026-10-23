import 'package:flutter/material.dart';
import 'screens/catalogo_equipos.dart';
import 'screens/escaner_qr.dart';

void main() {
  runApp(const MiAplicacion());
}

class MiAplicacion extends StatelessWidget {
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Préstamo de equipos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const PantallaLogin(),
    );
  }
}

// PANTALLA DE INICIO DE SESIÓN
class PantallaLogin extends StatelessWidget {
  const PantallaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.school,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),

                const Text(
                  'Préstamo de equipos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Inicia sesión con tu cuenta institucional',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PantallaPrincipal(),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// PANTALLA PRINCIPAL
class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préstamo de equipos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¡Hola, estudiante!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              const Text(
                '¿Qué deseas hacer hoy?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              _crearOpcion(
                context,
                icono: Icons.inventory_2_outlined,
                titulo: 'Catálogo de equipos',
                descripcion: 'Consulta equipos disponibles',
              ),

              _crearOpcion(
                context,
                icono: Icons.qr_code_scanner,
                titulo: 'Escanear QR',
                descripcion: 'Identifica un equipo',
              ),

              _crearOpcion(
                context,
                icono: Icons.assignment_outlined,
                titulo: 'Mis solicitudes',
                descripcion: 'Consulta tus solicitudes',
              ),

              _crearOpcion(
                context,
                icono: Icons.history,
                titulo: 'Historial de préstamos',
                descripcion: 'Revisa tus préstamos anteriores',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CREA CADA OPCIÓN DEL MENÚ
  Widget _crearOpcion(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Icon(
          icono,
          size: 32,
          color: Colors.blue,
        ),
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(descripcion),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
         
       

onTap: () {
  if (titulo.contains('Catálogo')) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const CatalogoEquipos(),
      ),
    );
  } else if (titulo.contains('Escanear QR')) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EscanerQR(),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$titulo: próximamente'),
      ),
    );
  }
},



      ),
    );
  }
}
