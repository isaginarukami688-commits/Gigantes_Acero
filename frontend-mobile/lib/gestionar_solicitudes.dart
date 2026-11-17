
import 'package:flutter/material.dart';
import 'services/api_service.dart';

class GestionarSolicitudes extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const GestionarSolicitudes({
    super.key,
    required this.usuario,
  });

  @override
  State<GestionarSolicitudes> createState() =>
      _GestionarSolicitudesState();
}

class _GestionarSolicitudesState extends State<GestionarSolicitudes> {
  late Future<List<Map<String, dynamic>>> _solicitudesFuture;
  bool _procesando = false;

  int get administradorId =>
      (widget.usuario['id'] as num).toInt();

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
  }

  void _cargarSolicitudes() {
    _solicitudesFuture =
        ApiService.listarSolicitudesAdmin(administradorId);
  }

  Future<void> _actualizar() async {
    setState(_cargarSolicitudes);
  }

  Future<void> _resolver(
    Map<String, dynamic> solicitud,
    bool aprobar,
  ) async {
    final id = (solicitud['id'] as num).toInt();

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(aprobar ? 'Aprobar solicitud' : 'Rechazar solicitud'),
        content: Text(
          aprobar
              ? '¿Deseas aprobar esta solicitud y registrar el préstamo?'
              : '¿Deseas rechazar esta solicitud?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(aprobar ? 'Aprobar' : 'Rechazar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);

    try {
      final mensaje = aprobar
          ? await ApiService.aprobarSolicitud(administradorId, id)
          : await ApiService.rechazarSolicitud(administradorId, id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );

      setState(_cargarSolicitudes);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  String _fecha(dynamic valor) {
    if (valor == null) return 'No disponible';

    try {
      final fecha = DateTime.parse(valor.toString()).toLocal();
      return '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year}';
    } catch (_) {
      return valor.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar solicitudes'),
        actions: [
          IconButton(
            onPressed: _procesando ? null : _actualizar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _solicitudesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 50),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudieron cargar las solicitudes.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _actualizar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final solicitudes = snapshot.data ?? [];

          if (solicitudes.isEmpty) {
            return const Center(
              child: Text('Todavía no hay solicitudes registradas.'),
            );
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _actualizar,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: solicitudes.length,
                  itemBuilder: (context, index) {
                    final solicitud = solicitudes[index];
                    final estado =
                        solicitud['estado']?.toString().toUpperCase() ?? '';
                    final pendiente = estado == 'PENDIENTE';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    solicitud['equipoNombre']?.toString() ??
                                        'Equipo',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Chip(label: Text(estado)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Estudiante: ${solicitud['usuarioNombre'] ?? 'No disponible'}',
                            ),
                            Text(
                              'Correo: ${solicitud['correo'] ?? 'No disponible'}',
                            ),
                            Text(
                              'Código: ${solicitud['codigoInventario'] ?? 'No disponible'}',
                            ),
                            const Divider(height: 24),
                            Text('Motivo: ${solicitud['motivo'] ?? 'Sin motivo'}'),
                            const SizedBox(height: 8),
                            Text('Inicio: ${_fecha(solicitud['fechaInicio'])}'),
                            Text('Fin: ${_fecha(solicitud['fechaFin'])}'),
                            if (solicitud['observaciones'] != null &&
                                solicitud['observaciones'].toString().isNotEmpty)
                              Text(
                                'Observaciones: ${solicitud['observaciones']}',
                              ),
                            if (pendiente) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _procesando
                                          ? null
                                          : () => _resolver(solicitud, false),
                                      child: const Text('Rechazar'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: _procesando
                                          ? null
                                          : () => _resolver(solicitud, true),
                                      child: const Text('Aprobar'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_procesando)
                const ColoredBox(
                  color: Color(0x33000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
