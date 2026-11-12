# Actualización propuesta — Gigantes de Acero

## Contenido
- `backend/`: backend Java/Javalin con endpoints administrativos para equipos, QR, préstamos y devoluciones.
- `frontend-mobile/`: Flutter con pantallas administrativas y llamadas al backend.
- `database/`: esquema actual y archivo `02_operaciones.sql` corregido para no duplicar tablas.

## Antes de reemplazar
1. Haz una copia de tu carpeta actual `C:\src\Gigantes_Acero_Respaldo`.
2. No ejecutes nuevamente `01_schema.sql` sobre una base que ya tiene datos.
3. No cambies `DB_PASSWORD`, `application.properties` ni la URL Tailscale configurada.

## Integración
Copia el contenido de `backend` sobre la carpeta `backend` de tu proyecto, y el contenido de `frontend-mobile` sobre `frontend-mobile`, aceptando reemplazar los archivos.
Conserva tu `Iniciar_Backend.ps1`, `Iniciar_Backend.bat`, archivos locales y variables de entorno.

## Compilar y probar
Backend (PowerShell):
```powershell
cd C:\src\Gigantes_Acero_Respaldo\backend
mvn clean compile
```
Iniciar como ya lo haces:
```powershell
& "C:\src\Gigantes_Acero_Respaldo\Iniciar_Backend.bat"
```

Flutter (PowerShell):
```powershell
cd C:\src\Gigantes_Acero_Respaldo\frontend-mobile
flutter pub get
flutter analyze
flutter run
```

## Funciones añadidas
- Administrar equipos: alta, edición de datos y baja lógica.
- Códigos QR: generar/mostrar QR con el código de inventario que el escáner ya consulta.
- Préstamos: consultar préstamos activos y registrar devolución.
- Historial administrativo: consultar todos los préstamos.

La devolución actualiza el préstamo, deja disponible el equipo y registra el cambio en `historial_estados`.

## Importante
La compilación Java de sintaxis de los archivos del backend se verificó localmente con stubs de las dependencias externas; no se pudo ejecutar `mvn` ni `flutter analyze` en este entorno. Por eso la prueba definitiva debe hacerse en tu laptop con los comandos anteriores. Si `flutter pub get` no logra descargar `qr_flutter`, revisa conexión a pub.dev antes de probar la pantalla QR.
