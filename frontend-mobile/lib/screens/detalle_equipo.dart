import '../crear_solicitud.dart';
import 'package:flutter/material.dart';

class DetalleEquipo extends StatelessWidget {
  final Map<String, dynamic> equipo;
  final int usuarioId;

  const DetalleEquipo({
    super.key,
    required this.equipo,
    required this.usuarioId,
  });
  @override
  Widget build(BuildContext context) {
    final estado = equipo['estado']?.toString().toUpperCase() ?? '';
    final disponible = estado == 'DISPONIBLE';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del equipo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.blue.shade50,
                child: Icon(
                  Icons.devices,
                  size: 60,
                  color: Colors.blue.shade800,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              equipo['nombre']?.toString() ?? 'Equipo',
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _dato('Código', equipo['codigo']?.toString()),
            _dato(
              'Laboratorio',
              equipo['laboratorio']?.toString() ??
                  'Laboratorio ${equipo['laboratorioId'] ?? 'No disponible'}',
            ),
            _dato('Descripción', equipo['descripcion']?.toString()),
            _dato('Estado', estado),

            const Spacer(),

            SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: disponible
        ? () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CrearSolicitud(
                  usuarioId: usuarioId,
                  equipoId: (equipo['id'] as num).toInt(),
                ),
              ),
            );
          }
        : null,
    icon: const Icon(Icons.assignment_outlined),
    label: Text(
      disponible
          ? 'Solicitar préstamo'
          : 'Equipo no disponible',
    ),
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.blue.shade800,
      foregroundColor: Colors.white,
    ),
  ),
),
          ],
        ),
      ),
    );
  }

  Widget _dato(String titulo, String? valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor ?? 'No disponible',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
