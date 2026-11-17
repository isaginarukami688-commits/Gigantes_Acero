
import 'package:flutter/material.dart';
import 'services/api_service.dart';

class HistorialPrestamos extends StatefulWidget {
  final int usuarioId;

  const HistorialPrestamos({
    super.key,
    required this.usuarioId,
  });

  @override
  State<HistorialPrestamos> createState() =>
      _HistorialPrestamosState();
}

class _HistorialPrestamosState extends State<HistorialPrestamos> {
  late Future<List<Map<String, dynamic>>> _futuroPrestamos;

  @override
  void initState() {
    super.initState();
    _cargarPrestamos();
  }

  void _cargarPrestamos() {
    _futuroPrestamos =
        ApiService.listarPrestamos(widget.usuarioId);
  }

  Future<void> _actualizar() async {
    setState(() {
      _cargarPrestamos();
    });

    await _futuroPrestamos;
  }

  String _fecha(dynamic valor) {
    if (valor == null || valor.toString().isEmpty) {
      return 'Pendiente';
    }

    try {
      final fecha = DateTime.parse(valor.toString()).toLocal();

      return '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year}';
    } catch (_) {
      return valor.toString();
    }
  }

  Color _colorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'ACTIVO':
        return Colors.green;
      case 'DEVUELTO':
      case 'FINALIZADO':
        return Colors.blue;
      case 'VENCIDO':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _devolver(Map<String, dynamic> prestamo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Devolver equipo'),
        content: Text(
          '¿Confirmas que deseas registrar la devolución de ${prestamo['equipoNombre']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final mensaje = await ApiService.devolverPrestamoUsuario(
        widget.usuarioId,
        (prestamo['id'] as num).toInt(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
      setState(_cargarPrestamos);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de préstamos'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futuroPrestamos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text('No se pudo cargar el historial.'),
                  TextButton(
                    onPressed: _actualizar,
                    child: const Text('Intentar nuevamente'),
                  ),
                ],
              ),
            );
          }

          final prestamos = snapshot.data ?? [];

          if (prestamos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 65,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text('Aún no tienes préstamos registrados.'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _actualizar,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prestamos.length,
              itemBuilder: (context, index) {
                final prestamo = prestamos[index];

                final estado =
                    (prestamo['estado'] ?? 'DESCONOCIDO').toString();

                final color = _colorEstado(estado);

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.laptop_mac,
                              color: Colors.blue,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                prestamo['equipoNombre'] ??
                                    'Equipo sin nombre',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Código: ${prestamo['codigoInventario'] ?? 'No disponible'}',
                        ),
                        Text(
                          'Fecha de préstamo: ${_fecha(prestamo['fechaPrestamo'])}',
                        ),
                        Text(
                          'Devolución prevista: ${_fecha(prestamo['fechaDevolucionPrevista'])}',
                        ),
                        Text(
                          'Devolución real: ${_fecha(prestamo['fechaDevolucionReal'])}',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Estado: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(estado),
                              backgroundColor: color.withOpacity(0.15),
                              labelStyle: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (prestamo['observaciones'] != null &&
                            prestamo['observaciones'].toString().isNotEmpty)
                          Text(
                            'Observaciones: ${prestamo['observaciones']}',
                          ),
                        if (estado.toUpperCase() == 'ACTIVO') ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.icon(
                              onPressed: () => _devolver(prestamo),
                              icon: const Icon(Icons.assignment_return),
                              label: const Text('Devolver equipo'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
