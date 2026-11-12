import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'services/api_service.dart';

class AdminEquiposScreen extends StatefulWidget {
  final int adminId;
  const AdminEquiposScreen({super.key, required this.adminId});
  @override
  State<AdminEquiposScreen> createState() => _AdminEquiposScreenState();
}

class _AdminEquiposScreenState extends State<AdminEquiposScreen> {
  late Future<List<Map<String,dynamic>>> _future;
  bool _mostrarInactivos = false;
  @override
  void initState(){super.initState();_cargar();}
  void _cargar(){_future=ApiService.listarEquiposAdmin(widget.adminId);}
  Future<void> _refrescar() async {setState(_cargar); await _future;}

  Future<void> _formulario({Map<String,dynamic>? equipo}) async {
    final formKey=GlobalKey<FormState>();
    final codigo=TextEditingController(text: equipo?['codigo']?.toString() ?? '');
    final nombre=TextEditingController(text: equipo?['nombre']?.toString() ?? '');
    final descripcion=TextEditingController(text: equipo?['descripcion']?.toString() ?? '');
    final laboratorio=TextEditingController(text: equipo?['laboratorioId']?.toString() ?? '1');
    final ok=await showDialog<bool>(context:context,builder:(ctx)=>AlertDialog(
      title:Text(equipo==null?'Agregar equipo':'Editar equipo'),
      content:Form(key:formKey,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextFormField(controller:codigo,decoration:const InputDecoration(labelText:'Código de inventario'),validator:(v)=>v==null||v.trim().isEmpty?'Campo obligatorio':null),
        TextFormField(controller:nombre,decoration:const InputDecoration(labelText:'Nombre'),validator:(v)=>v==null||v.trim().isEmpty?'Campo obligatorio':null),
        TextFormField(controller:descripcion,decoration:const InputDecoration(labelText:'Descripción')),
        TextFormField(controller:laboratorio,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'ID del laboratorio'),validator:(v)=>int.tryParse(v??'')==null?'Ingresa un ID válido':null),

      ]))),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(ctx,formKey.currentState!.validate()),child:const Text('Guardar')),
      ],
    ));
    if(ok!=true)return;
    try{
      final mensaje=await ApiService.guardarEquipo(widget.adminId,{
        'codigo':codigo.text.trim(),'nombre':nombre.text.trim(),
        'descripcion':descripcion.text.trim(),'laboratorioId':int.parse(laboratorio.text),
        'estado':equipo?['estado'] ?? 'DISPONIBLE',
      },equipoId:equipo==null?null:(equipo['id'] as num).toInt());
      if(!mounted)return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(mensaje)));
      setState(_cargar);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }

  Future<void> _baja(Map<String,dynamic> e) async {
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Dar de baja equipo'),
      content:Text('¿Deseas dar de baja ${e['nombre']}?'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Confirmar'))],
    ));
    if(ok!=true)return;
    try{final m=await ApiService.eliminarEquipo(widget.adminId,(e['id'] as num).toInt());if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));setState(_cargar);}}
    catch(err){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(err.toString())));}
  }

  Future<void> _reactivar(Map<String,dynamic> e) async {
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Reactivar equipo'),
      content:Text('¿Deseas reactivar ${e['nombre']}?'),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),
        FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Reactivar')),
      ],
    ));
    if(ok!=true)return;
    try{
      final m=await ApiService.reactivarEquipo(widget.adminId,(e['id'] as num).toInt());
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));
        setState(_cargar);
      }
    }catch(err){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(err.toString())));
    }
  }

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(_mostrarInactivos ? 'Equipos dados de baja' : 'Administrar equipos'),actions:[IconButton(tooltip:_mostrarInactivos ? 'Ver activos' : 'Ver dados de baja',onPressed:(){setState((){_mostrarInactivos=!_mostrarInactivos;});},icon:Icon(_mostrarInactivos ? Icons.inventory_2 : Icons.archive)),IconButton(onPressed:_refrescar,icon:const Icon(Icons.refresh))]),
    floatingActionButton:FloatingActionButton.extended(onPressed:()=>_formulario(),icon:const Icon(Icons.add),label:const Text('Agregar')),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:_future,builder:(c,s){
      if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Text('Error: ${s.error}'));
      final todos=s.data??[];
      final items=todos.where((e)=>(e['activo']==true) != _mostrarInactivos).toList();
      if(items.isEmpty)return Center(child:Text(_mostrarInactivos ? 'No hay equipos dados de baja.' : 'No hay equipos activos.'));
      return RefreshIndicator(onRefresh:_refrescar,child:ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(c,i){
        final e=items[i];final activo=e['activo']==true;
        return Card(child:ListTile(
          leading:const Icon(Icons.devices),title:Text(e['nombre']?.toString()??'Equipo'),
          subtitle:Text('Código: ${e['codigo']??'-'}\nLaboratorio: ${e['laboratorio']??e['laboratorioId']??'-'}\nEstado: ${e['estado']??'-'}${activo?'':' · INACTIVO'}'),
          isThreeLine:true,
          trailing:PopupMenuButton<String>(
            onSelected:(v){
              if(v=='editar')_formulario(equipo:e);
              if(v=='baja')_baja(e);
              if(v=='reactivar')_reactivar(e);
            },
            itemBuilder:(_)=>[
              const PopupMenuItem(value:'editar',child:Text('Editar')),
              if(activo)
                const PopupMenuItem(value:'baja',child:Text('Dar de baja'))
              else
                const PopupMenuItem(value:'reactivar',child:Text('Reactivar')),
            ],
          ),
        ));
      }));
    }),
  );
}

class AdminPrestamosScreen extends StatefulWidget {
  final int adminId;
  final bool historial;
  const AdminPrestamosScreen({super.key,required this.adminId,this.historial=false});
  @override State<AdminPrestamosScreen> createState()=>_AdminPrestamosScreenState();
}
class _AdminPrestamosScreenState extends State<AdminPrestamosScreen>{
  late Future<List<Map<String,dynamic>>> _future;
  @override void initState(){super.initState();_cargar();}
  void _cargar(){_future=ApiService.listarPrestamosAdmin(widget.adminId);}
  Future<void> _refresh()async{setState(_cargar);await _future;}
  String _fecha(dynamic v){if(v==null)return '—';try{final d=DateTime.parse(v.toString()).toLocal();return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';}catch(_){return v.toString();}}
  Future<void> _devolver(Map<String,dynamic> p)async{
    final ok=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
      title:const Text('Registrar devolución'),content:Text('¿Confirmas la devolución de ${p['equipoNombre']}?'),
      actions:[TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Confirmar'))],
    ));
    if(ok!=true)return;
    try{final m=await ApiService.devolverPrestamo(widget.adminId,(p['id'] as num).toInt());if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(m)));setState(_cargar);}}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:Text(widget.historial?'Historial de préstamos':'Préstamos')),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:_future,builder:(c,s){
      if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Text('Error: ${s.error}'));
      final all=s.data??[];
      final items=widget.historial?all:all.where((p)=>p['estado']=='ACTIVO').toList();
      if(items.isEmpty)return Center(child:Text(widget.historial?'Aún no hay préstamos registrados.':'No hay préstamos activos.'));
      return RefreshIndicator(onRefresh:_refresh,child:ListView.builder(padding:const EdgeInsets.all(12),itemCount:items.length,itemBuilder:(c,i){
        final p=items[i];final activo=p['estado']=='ACTIVO';
        return Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Expanded(child:Text(p['equipoNombre']?.toString()??'Equipo',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17))),Chip(label:Text(p['estado']?.toString()??''))]),
          Text('Estudiante: ${p['usuarioNombre']??'—'}'),
          Text('Código: ${p['codigoInventario']??'—'}'),
          Text('Préstamo: ${_fecha(p['fechaPrestamo'])}'),
          Text('Devolución prevista: ${_fecha(p['fechaDevolucionPrevista'])}'),
          if(p['fechaDevolucionReal']!=null)Text('Devuelto: ${_fecha(p['fechaDevolucionReal'])}'),
          if(activo&&!widget.historial)...[const SizedBox(height:10),SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:()=>_devolver(p),icon:const Icon(Icons.assignment_turned_in),label:const Text('Registrar devolución')))],
        ])));
      }));
    }),
  );
}

class AdminQrScreen extends StatefulWidget {
  final int adminId;
  const AdminQrScreen({super.key,required this.adminId});
  @override State<AdminQrScreen> createState()=>_AdminQrScreenState();
}
class _AdminQrScreenState extends State<AdminQrScreen>{
  late Future<List<Map<String,dynamic>>> _future;
  @override void initState(){super.initState();_future=ApiService.listarQrAdmin(widget.adminId);}
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Códigos QR'),actions:[IconButton(onPressed:()=>setState(()=>_future=ApiService.listarQrAdmin(widget.adminId)),icon:const Icon(Icons.refresh))]),
    body:FutureBuilder<List<Map<String,dynamic>>>(future:_future,builder:(c,s){
      if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Text('Error: ${s.error}'));
      final items=(s.data??[]).where((e)=>e['activo']==true).toList();
      if(items.isEmpty)return const Center(child:Text('No hay equipos activos para generar QR.'));
      return ListView.builder(padding:const EdgeInsets.all(16),itemCount:items.length,itemBuilder:(c,i){
        final e=items[i];final code=e['codigoQr']?.toString()??e['codigo']?.toString()??'';
        return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(children:[
          Text(e['nombre']?.toString()??'Equipo',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
          const SizedBox(height:10),QrImageView(data:code,size:190,backgroundColor:Colors.white),
          SelectableText(code,style:const TextStyle(fontWeight:FontWeight.w600)),
          Text('Código de inventario: ${e['codigo']??''}'),
        ])));
      });
    }),
  );
}

class AdminHistorialEstadosScreen extends StatefulWidget {
  final int adminId;

  const AdminHistorialEstadosScreen({super.key, required this.adminId});

  @override
  State<AdminHistorialEstadosScreen> createState() =>
      _AdminHistorialEstadosScreenState();
}

class _AdminHistorialEstadosScreenState
    extends State<AdminHistorialEstadosScreen> {
  late Future<List<Map<String,dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _future = ApiService.listarHistorialEstadosAdmin(widget.adminId);
  }

  Future<void> _refrescar() async {
    setState(_cargar);
    await _future;
  }

  String _fecha(dynamic valor) {
    if (valor == null) return 'Sin fecha';
    try {
      final fecha = DateTime.parse(valor.toString()).toLocal();
      return '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:'
          '${fecha.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return valor.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de estados'),
        actions: [
          IconButton(
            onPressed: _refrescar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String,dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text('Todavía no hay cambios de estado registrados.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refrescar,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final h = items[index];
                final anterior =
                    h['estadoAnterior']?.toString() ?? 'Sin estado anterior';
                final nuevo =
                    h['estadoNuevo']?.toString() ?? 'Sin estado nuevo';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.devices, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                h['equipoNombre']?.toString() ?? 'Equipo',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Código: ${h['codigoInventario'] ?? '-'}'),
                        const SizedBox(height: 6),
                        Text('$anterior  →  $nuevo'),
                        const SizedBox(height: 6),
                        Text('Fecha: ${_fecha(h['fechaCambio'])}'),
                        Text(
                          'Usuario: ${h['usuarioNombre'] ?? 'No especificado'}',
                        ),
                        if (h['observaciones'] != null &&
                            h['observaciones'].toString().trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Observaciones: ${h['observaciones']}',
                            ),
                          ),
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