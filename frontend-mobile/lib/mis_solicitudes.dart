
import 'package:flutter/material.dart';
import 'services/api_service.dart';

class MisSolicitudes extends StatefulWidget {
  final int usuarioId;

  const MisSolicitudes({
    super.key,
    required this.usuarioId,
  });

  @override
  State<MisSolicitudes> createState() => _MisSolicitudesState();
}

class _MisSolicitudesState extends State<MisSolicitudes> {
  List<Map<String, dynamic>> _solicitudes = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  Future<void> _cargarSolicitudes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final solicitudes =
          await ApiService.listarSolicitudes(widget.usuarioId);

      if (!mounted) return;

      setState(() {
        _solicitudes = solicitudes;
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudieron cargar tus solicitudes.';
        _cargando = false;
      });
    }
  }

  String _obtenerTexto(
    Map<String, dynamic> solicitud,
    List<String> claves, {
    String predeterminado = 'No disponible',
  }) {
    for (final clave in claves) {
      final valor = solicitud[clave];

      if (valor != null && valor.toString().trim().isNotEmpty) {
        return valor.toString();
      }
    }

    return predeterminado;
  }

  String _formatearFecha(String valor) {
    try {
      final fecha = DateTime.parse(valor).toLocal();
      final dia = fecha.day.toString().padLeft(2, '0');
      final mes = fecha.month.toString().padLeft(2, '0');
      final hora = fecha.hour.toString().padLeft(2, '0');
      final minuto = fecha.minute.toString().padLeft(2, '0');

      return '$dia/$mes/${fecha.year} $hora:$minuto';
    } catch (_) {
      return valor;
    }
  }

  Color _colorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'APROBADA':
      case 'APROBADO':
        return Colors.green;
      case 'RECHAZADA':
      case 'RECHAZADO':
        return Colors.red;
      case 'PENDIENTE':
        return Colors.orange.shade800;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargarSolicitudes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _cargarSolicitudes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Intentar de nuevo'),
                        ),
                      ],
                    ),
                  ),
                )
              : _solicitudes.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Todavía no tienes solicitudes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _cargarSolicitudes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _solicitudes.length,
                        itemBuilder: (context, index) {
                          final solicitud = _solicitudes[index];

                          final estado = _obtenerTexto(
                            solicitud,
                            ['estado', 'estatus'],
                            predeterminado: 'Sin estado',
                          );

                          final equipo = _obtenerTexto(
                            solicitud,
                            [
                              'equipoNombre',
                              'nombreEquipo',
                              'equipo',
                            ],
                          );

                          final motivo = _obtenerTexto(
                            solicitud,
                            ['motivo', 'descripcion'],
                          );

                          final inicio = _obtenerTexto(
                            solicitud,
                            ['fechaInicio', 'fecha_inicio'],
                          );

                          final fin = _obtenerTexto(
                            solicitud,
                            ['fechaFin', 'fecha_fin'],
                          );

                          final id = _obtenerTexto(
                            solicitud,
                            ['id', 'solicitudId'],
                          );

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.assignment,
                                        color: Colors.blue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Solicitud #$id',
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _colorEstado(estado)
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          estado,
                                          style: TextStyle(
                                            color: _colorEstado(estado),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  Text(
                                    'Equipo: $equipo',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Motivo: $motivo'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Inicio: ${_formatearFecha(inicio)}',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Fin: ${_formatearFecha(fin)}',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
