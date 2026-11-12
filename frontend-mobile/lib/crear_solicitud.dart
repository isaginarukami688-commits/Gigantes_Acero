
import 'package:flutter/material.dart';
import 'services/api_service.dart';

class CrearSolicitud extends StatefulWidget {
  final int usuarioId;
  final int equipoId;

  const CrearSolicitud({
    super.key,
    required this.usuarioId,
    required this.equipoId,
  });

  @override
  State<CrearSolicitud> createState() => _CrearSolicitudState();
}

class _CrearSolicitudState extends State<CrearSolicitud> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _equipoController;
  final _motivoController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _cargando = false;

  @override
void initState() {
  super.initState();
  _equipoController = TextEditingController(
    text: widget.equipoId.toString(),
  );
}

  Future<DateTime?> _seleccionarFechaHora() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha == null || !mounted) return null;

    final hora = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );

    if (hora == null) return null;

    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Seleccionar fecha y hora';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year} - $hora:$minuto';
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    if (_fechaInicio == null || _fechaFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona la fecha de inicio y de fin.'),
        ),
      );
      return;
    }

    if (!_fechaFin!.isAfter(_fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin debe ser posterior al inicio.'),
        ),
      );
      return;
    }

    setState(() => _cargando = true);

    final resultado = await ApiService.crearSolicitud(
      usuarioId: widget.usuarioId,
      equipoId: int.parse(_equipoController.text.trim()),
      fechaInicio: _fechaInicio!,
      fechaFin: _fechaFin!,
      motivo: _motivoController.text,
    );

    if (!mounted) return;

    setState(() => _cargando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultado['mensaje'].toString()),
      ),
    );

    if (resultado['exito'] == true) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear solicitud'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.assignment_add,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Solicitud de préstamo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
  'ID del equipo seleccionado: ${widget.equipoId}',
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
),
const SizedBox(height: 16),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final fecha = await _seleccionarFechaHora();
                    if (fecha != null && mounted) {
                      setState(() => _fechaInicio = fecha);
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    'Inicio: ${_formatearFecha(_fechaInicio)}',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final fecha = await _seleccionarFechaHora();
                    if (fecha != null && mounted) {
                      setState(() => _fechaFin = fecha);
                    }
                  },
                  icon: const Icon(Icons.event_available),
                  label: Text(
                    'Fin: ${_formatearFecha(_fechaFin)}',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _motivoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Motivo del préstamo',
                    hintText: '¿Para qué necesitas el equipo?',
                    prefixIcon: Icon(Icons.edit_note),
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Escribe el motivo del préstamo.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _cargando ? null : _enviarSolicitud,
                  icon: _cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _cargando
                        ? 'Enviando...'
                        : 'Enviar solicitud',
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
