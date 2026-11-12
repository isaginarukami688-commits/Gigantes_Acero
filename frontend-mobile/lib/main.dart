import 'package:flutter/material.dart';
import 'screens/catalogo_equipos.dart';
import 'screens/escaner_qr.dart';
import 'services/api_service.dart';
import 'perfil_usuario.dart';
import 'mis_solicitudes.dart';
import 'crear_solicitud.dart';
import 'historial_prestamos.dart';
import 'gestionar_solicitudes.dart';
import 'admin_modulos.dart';

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
class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController _correoController =
      TextEditingController();

  final TextEditingController _contrasenaController =
      TextEditingController();

  bool _cargando = false;
  bool _mostrarContrasena = false;

  @override
  void dispose() {
    _correoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

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
                  controller: _correoController,
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
  controller: _contrasenaController,
  obscureText: !_mostrarContrasena,
  decoration: InputDecoration(
    labelText: 'Contraseña',
    prefixIcon: const Icon(Icons.lock_outline),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    suffixIcon: IconButton(
      icon: Icon(
        _mostrarContrasena
            ? Icons.visibility_off
            : Icons.visibility,
      ),
      onPressed: () {
        setState(() {
          _mostrarContrasena = !_mostrarContrasena;
        });
      },
    ),
  ),
),
const SizedBox(height: 16),


                
                const SizedBox(height: 24),
OutlinedButton.icon(
  onPressed: () async {
    final conectado = await ApiService.comprobarBackend();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          conectado
              ? 'Conexión con el backend exitosa'
              : 'No se pudo conectar con el backend',
        ),
      ),
    );
  },
  icon: const Icon(Icons.cloud_outlined),
  label: const Text('Probar conexión con el servidor'),
),

const SizedBox(height: 12),
                FilledButton(
                  onPressed: _cargando
    ? null
    : () async {
        final correo = _correoController.text.trim();
        final contrasena = _contrasenaController.text;

        if (correo.isEmpty || contrasena.isEmpty) {
          ScaffoldMessenger.of(this.context).showSnackBar(
            const SnackBar(
              content: Text('Ingresa tu correo y contraseña.'),
            ),
          );
          return;
        }

        setState(() {
          _cargando = true;
        });

        final resultado = await ApiService.iniciarSesion(
          correo: correo,
          contrasena: contrasena,
        );

        if (!mounted) return;

        setState(() {
          _cargando = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultado['mensaje'].toString()),
          ),
        );

if (resultado['exito'] == true) {
  final usuario = Map<String, dynamic>.from(
    resultado['usuario'],
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PantallaPrincipal(
        usuario: usuario,
      ),
    ),
  );
}
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
  final Map<String, dynamic> usuario;

  const PantallaPrincipal({
    super.key,
    required this.usuario,
  });
  @override
Widget build(BuildContext context) {
  final int rolId = (usuario['rolId'] as num?)?.toInt() ?? 3;

  if (rolId == 1) {
    return PantallaAdministrador(usuario: usuario);
  }

  return Scaffold(
     appBar: AppBar(
  title: const Text('Préstamo de equipos'),
  centerTitle: true,
  actions: [
    IconButton(
      icon: const Icon(Icons.account_circle_outlined),
      tooltip: 'Mi perfil',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PerfilUsuario(
              usuario: usuario,
            ),
          ),
        );
      },
    ),
  ],
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
                icono: Icons.add_task,
                titulo: 'Crear solicitud',
                descripcion: 'Solicita el préstamo de un equipo',
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
       builder: (_) => CatalogoEquipos(
  usuarioId: (usuario['id'] as num).toInt(),
),
      ),
    );
  } else if (titulo.contains('Escanear QR')) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EscanerQR(),
      ),
    );
  } else if (titulo == 'Mis solicitudes') {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => MisSolicitudes(
        usuarioId: (usuario['id'] as num).toInt(),
      ),
    ),
  );
  } else if (titulo == 'Historial de préstamos') {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => HistorialPrestamos(
        usuarioId: (usuario['id'] as num).toInt(),
      ),
    ),
  );
} else if (titulo == 'Crear solicitud') {
  Navigator.of(context).push(
    MaterialPageRoute<bool>(
     builder: (_) => CrearSolicitud(
  usuarioId: (usuario['id'] as num).toInt(),
  equipoId: 1,
),
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


class PantallaAdministrador extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const PantallaAdministrador({
    super.key,
    required this.usuario,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel administrativo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Mi perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilUsuario(usuario: usuario),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 65,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),

              Text(
                '¡Hola, ${usuario['nombre']}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Panel de administración de equipos',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              _opcion(
                context,
                Icons.inventory_2_outlined,
                'Administrar equipos',
                'Agregar, editar y eliminar equipos',
              ),

              _opcion(
                context,
                Icons.assignment_outlined,
                'Gestionar solicitudes',
                'Aceptar o rechazar solicitudes',
              ),

              _opcion(
                context,
                Icons.qr_code_2,
                'Códigos QR',
                'Generar y consultar códigos QR',
              ),

              _opcion(
                context,
                Icons.handshake_outlined,
                'Préstamos',
                'Registrar entregas y devoluciones',
              ),

              _opcion(
                context,
                Icons.history,
                'Historial de préstamos',
                'Consultar los préstamos registrados',
              ),
              _opcion(
                context,
                Icons.history,
                'Historial de estados',
                'Consultar los cambios de estado de los equipos',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcion(
  BuildContext context,
  IconData icono,
  String titulo,
  String descripcion,
) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: Icon(icono, size: 32, color: Colors.blue),
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(descripcion),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
     onTap: () {
  if (titulo == 'Gestionar solicitudes') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GestionarSolicitudes(usuario: usuario)),
    );
  } else {
    final adminId = (usuario['id'] as num).toInt();
    Widget pantalla;
    if (titulo == 'Administrar equipos') {
      pantalla = AdminEquiposScreen(adminId: adminId);
    } else if (titulo == 'Códigos QR') {
      pantalla = AdminQrScreen(adminId: adminId);
    } else if (titulo == 'Préstamos') {
      pantalla = AdminPrestamosScreen(adminId: adminId);
    } else if (titulo == 'Historial de préstamos') {
      pantalla = AdminPrestamosScreen(adminId: adminId, historial: true);
    } else if (titulo == 'Historial de estados') {
      pantalla = AdminHistorialEstadosScreen(adminId: adminId);
    } else {
      pantalla = PantallaModuloAdmin(titulo: titulo, descripcion: descripcion, icono: icono);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));
  }
},
    ),
  );
}
}

class PantallaModuloAdmin extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;

  const PantallaModuloAdmin({
    super.key,
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 75, color: Colors.blue),
              const SizedBox(height: 20),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                descripcion,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Módulo en desarrollo',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
