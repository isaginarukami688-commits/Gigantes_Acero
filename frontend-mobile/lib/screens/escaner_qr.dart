import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class EscanerQR extends StatefulWidget {
  const EscanerQR({super.key});

  @override
  State<EscanerQR> createState() => _EscanerQRState();
}

class _EscanerQRState extends State<EscanerQR> {
  final MobileScannerController _controller =
      MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );

  String? _codigoLeido;
  Map<String, dynamic>? _equipoEncontrado;
bool _buscandoEquipo = false;
String? _errorBusqueda;

  Future<void> _alDetectarCodigo(BarcodeCapture captura) async {
  if (_codigoLeido != null || captura.barcodes.isEmpty) {
    return;
  }

  final codigo = captura.barcodes.first.rawValue?.trim();

  if (codigo == null || codigo.isEmpty) {
    return;
  }

  setState(() {
    _codigoLeido = codigo;
    _buscandoEquipo = true;
    _equipoEncontrado = null;
    _errorBusqueda = null;
  });

  await _controller.stop();

  try {
    final equipo = await ApiService.buscarEquipoPorCodigo(codigo);

    if (!mounted) return;

    setState(() {
      _equipoEncontrado = equipo;
      _buscandoEquipo = false;

      if (equipo == null) {
        _errorBusqueda = 'No se encontró un equipo con ese código.';
      }
    });
  } catch (_) {
    if (!mounted) return;

    setState(() {
      _buscandoEquipo = false;
      _errorBusqueda = 'No se pudo consultar el equipo en el servidor.';
    });
  }
}

    void _escanearDeNuevo() {
    setState(() {
      _codigoLeido = null;
      _equipoEncontrado = null;
      _buscandoEquipo = false;
      _errorBusqueda = null;
    });

    _controller.start();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detectado = _codigoLeido != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        title: const Text(
          'Escáner QR',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF123B70),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Escanea tu equipo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF183153),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Centra el código QR dentro del marco '
                'para identificar el equipo.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),

              Container(
                height: 350,
                decoration: BoxDecoration(
                  color: const Color(0xFF10243D),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _alDetectarCodigo,
                    ),
                    IgnorePointer(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF54E39A),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    if (!detectado)
                      Positioned(
                        bottom: 18,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: Color(0xFF54E39A),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Buscando código QR...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: detectado
                        ? const Color(0xFF9ADBB8)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      detectado
                          ? Icons.check_circle
                          : Icons.qr_code_2,
                      size: 38,
                      color: detectado
                          ? Colors.green
                          : const Color(0xFF2563A6),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      detectado
                          ? '¡Código detectado!'
                          : 'Listo para escanear',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF183153),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detectado
                          ? 'Contenido del código:'
                          : 'El resultado aparecerá aquí '
                              'cuando la cámara lea un QR.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    if (detectado) ...[
  const SizedBox(height: 12),

  // Código QR detectado
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: SelectableText(
      _codigoLeido!,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF183153),
      ),
    ),
  ),

  // Indicador de búsqueda
  if (_buscandoEquipo) ...[
    const SizedBox(height: 16),
    const CircularProgressIndicator(),
    const SizedBox(height: 8),
    const Text('Buscando equipo en el servidor...'),
  ],

  // Datos del equipo
  if (_equipoEncontrado != null) ...[
    const SizedBox(height: 16),
    const Divider(),
    const Text(
      'Equipo encontrado',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF183153),
      ),
    ),
    const SizedBox(height: 12),
    _datoEquipo(
      'Nombre',
      _equipoEncontrado!['nombre']?.toString() ?? 'Sin nombre',
    ),
    _datoEquipo(
      'Código',
      _equipoEncontrado!['codigo']?.toString() ?? 'Sin código',
    ),
    _datoEquipo(
      'Estado',
      _equipoEncontrado!['estado']?.toString() ?? 'Desconocido',
    ),
    _datoEquipo(
      'ID del equipo',
      _equipoEncontrado!['id']?.toString() ?? 'Sin ID',
    ),
  ],

  // Error de consulta
  if (_errorBusqueda != null) ...[
    const SizedBox(height: 16),
    Text(
      _errorBusqueda!,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w600,
      ),
    ),
  ],

  // Botón para escanear nuevamente
  const SizedBox(height: 16),
  SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: _escanearDeNuevo,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text('Escanear otro código'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF183153),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  ),
],
                   
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datoEquipo(String etiqueta, String valor) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            etiqueta,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            valor,
            style: const TextStyle(
              color: Color(0xFF183153),
            ),
          ),
        ),
      ],
    ),
  );
}
}
