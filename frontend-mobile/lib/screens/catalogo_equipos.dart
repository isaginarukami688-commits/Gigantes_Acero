import 'detalle_equipo.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CatalogoEquipos extends StatefulWidget {
  final int usuarioId;

  const CatalogoEquipos({
    super.key,
    required this.usuarioId,
  });

  @override
  State<CatalogoEquipos> createState() => _CatalogoEquiposState();
}

class _CatalogoEquiposState extends State<CatalogoEquipos> {
  final TextEditingController _busquedaController =
      TextEditingController();

  List<Map<String, dynamic>> _equipos = [];

  String _filtroEstado = 'Todos';
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    cargarEquipos();
  }

  Future<void> cargarEquipos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await ApiService.listarEquipos();

      if (!mounted) return;

      setState(() {
        _equipos = resultado;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busqueda = _busquedaController.text.toLowerCase();

    final equiposFiltrados = _equipos.where((equipo) {
      final nombre =
          (equipo['nombre'] ?? '').toString().toLowerCase();

      final codigo =
          (equipo['codigo'] ?? '').toString().toLowerCase();

      final laboratorio =
          (equipo['laboratorio'] ??
                  equipo['laboratorioId'] ??
                  '')
              .toString()
              .toLowerCase();

      final estado =
          (equipo['estado'] ?? '').toString().toUpperCase();

      final coincideBusqueda =
          nombre.contains(busqueda) ||
          codigo.contains(busqueda) ||
          laboratorio.contains(busqueda);

      final coincideEstado =
          _filtroEstado == 'Todos' ||
          estado == _filtroEstado.toUpperCase();

      return coincideBusqueda && coincideEstado;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de equipos'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar catálogo',
            onPressed: cargarEquipos,
          ),
        ],
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
                  value: 'DISPONIBLE',
                  child: Text('Disponibles'),
                ),
                DropdownMenuItem(
                  value: 'PRESTADO',
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

          const SizedBox(height: 10),

          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 55,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No se pudieron cargar los equipos.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: cargarEquipos,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : equiposFiltrados.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron equipos.',
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: cargarEquipos,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: equiposFiltrados.length,
                              itemBuilder: (context, index) {
                                final equipo =
                                    equiposFiltrados[index];

                                final estado =
                                    (equipo['estado'] ?? '')
                                        .toString()
                                        .toUpperCase();

                                final disponible =
                                    estado == 'DISPONIBLE';

                                final laboratorio =
                                    equipo['laboratorio'] ??
                                    'Laboratorio ${equipo['laboratorioId'] ?? 'No asignado'}';

                                return Card(
  margin: const EdgeInsets.only(
    bottom: 12,
  ),
  child: ListTile(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
         builder: (context) => DetalleEquipo(
  equipo: equipo,
  usuarioId: widget.usuarioId,
),
        ),
      );
    },
                                    contentPadding:
                                        const EdgeInsets.all(12),

                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Colors.blue.shade50,
                                      child: Icon(
                                        Icons.devices,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),

                                    title: Text(
                                      equipo['nombre']?.toString() ??
                                          'Sin nombre',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    subtitle: Padding(
                                      padding:
                                          const EdgeInsets.only(top: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Código: ${equipo['codigo'] ?? 'Sin código'}',
                                          ),
                                          Text(
                                            'Laboratorio: $laboratorio',
                                          ),
                                          if (equipo['descripcion'] != null)
                                            Text(
                                              equipo['descripcion'].toString(),
                                            ),
                                          const SizedBox(height: 6),
                                          Text(
                                            disponible
                                                ? 'DISPONIBLE'
                                                : estado,
                                            style: TextStyle(
                                              color: disponible
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade800,
                                              fontWeight: FontWeight.bold,
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
          ),
        ],
      ),
    );
  }
}
