
import 'package:flutter/material.dart';

class CatalogoEquipos extends StatefulWidget {
  const CatalogoEquipos({super.key});

  @override
  State<CatalogoEquipos> createState() => _CatalogoEquiposState();
}

class _CatalogoEquiposState extends State<CatalogoEquipos> {
  final TextEditingController _busquedaController =
      TextEditingController();

  String _filtroEstado = 'Todos';

  // Datos de prueba. Después los obtendremos del backend.
  final List<Map<String, String>> _equipos = [
    {
      'nombre': 'Laptop Dell',
      'codigo': 'EQ-001',
      'laboratorio': 'Laboratorio de Cómputo',
      'estado': 'Disponible',
    },
    {
      'nombre': 'Proyector Epson',
      'codigo': 'EQ-002',
      'laboratorio': 'Laboratorio Audiovisual',
      'estado': 'Disponible',
    },
    {
      'nombre': 'Arduino Uno',
      'codigo': 'EQ-003',
      'laboratorio': 'Laboratorio de Electrónica',
      'estado': 'Prestado',
    },
    {
      'nombre': 'Multímetro',
      'codigo': 'EQ-004',
      'laboratorio': 'Laboratorio de Electrónica',
      'estado': 'Disponible',
    },
  ];

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busqueda = _busquedaController.text.toLowerCase();

    final equiposFiltrados = _equipos.where((equipo) {
      final coincideBusqueda =
          equipo['nombre']!.toLowerCase().contains(busqueda) ||
          equipo['codigo']!.toLowerCase().contains(busqueda) ||
          equipo['laboratorio']!.toLowerCase().contains(busqueda);

      final coincideEstado = _filtroEstado == 'Todos' ||
          equipo['estado'] == _filtroEstado;

      return coincideBusqueda && coincideEstado;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de equipos'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _busquedaController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar equipo o código...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              value: _filtroEstado,
              decoration: const InputDecoration(
                labelText: 'Filtrar por estado',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Todos',
                  child: Text('Todos los equipos'),
                ),
                DropdownMenuItem(
                  value: 'Disponible',
                  child: Text('Disponibles'),
                ),
                DropdownMenuItem(
                  value: 'Prestado',
                  child: Text('Prestados'),
                ),
              ],
              onChanged: (valor) {
                if (valor != null) {
                  setState(() {
                    _filtroEstado = valor;
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: equiposFiltrados.isEmpty
                ? const Center(
                    child: Text('No se encontraron equipos.'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: equiposFiltrados.length,
                    itemBuilder: (context, index) {
                      final equipo = equiposFiltrados[index];
                      final disponible =
                          equipo['estado'] == 'Disponible';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade50,
                            child: Icon(
                              Icons.devices,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          title: Text(
                            equipo['nombre']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Código: ${equipo['codigo']}'),
                                Text(equipo['laboratorio']!),
                                const SizedBox(height: 6),
                                Text(
                                  equipo['estado']!,
                                  style: TextStyle(
                                    color: disponible
                                        ? Colors.green.shade700
                                        : Colors.orange.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
