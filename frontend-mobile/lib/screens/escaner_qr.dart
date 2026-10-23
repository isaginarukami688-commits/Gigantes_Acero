
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  void _alDetectarCodigo(BarcodeCapture captura) {
    if (_codigoLeido != null || captura.barcodes.isEmpty) {
      return;
    }

    final codigo = captura.barcodes.first.rawValue;

    if (codigo == null || codigo.trim().isEmpty) {
      return;
    }

    setState(() {
      _codigoLeido = codigo.trim();
    });

    _controller.stop();
  }

  void _escanearDeNuevo() {
    setState(() {
      _codigoLeido = null;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código QR'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Coloca el código QR dentro del área '
              'de la cámara.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _alDetectarCodigo,
                ),
                IgnorePointer(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.greenAccent,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_codigoLeido == null) ...[
                  const Text(
                    'Esperando código QR...',
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const Text(
                    '¡Código detectado!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _codigoLeido!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _escanearDeNuevo,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Escanear otro código'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
