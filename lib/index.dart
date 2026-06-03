// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:fcq_app/main.dart' as globals;
import 'package:fcq_app/actividad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fcq_app/funciones.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String mensaje = '';
  List<dynamic> datosAgenda = [];
  bool isLoading = false;
  ScrollController autoScroll = ScrollController();

  void actualizaAgenda(List<dynamic> agenda, bool L) {
    setState(() {
      datosAgenda = agenda;
      isLoading = L;
    });
  }

  void actualizaMensaje(String nuevoMensaje) {
    setState(() {
      mensaje = nuevoMensaje;
    });
  }

  @override
  void initState() {
    super.initState();
    isLoading = true;
    Funciones.obtenerAgenda(datosAgenda, isLoading, setState, actualizaAgenda, actualizaMensaje);
    Funciones.programarNotificaciones();
  }

  @override
  Widget build(BuildContext context) {
    autoScroll = Funciones.scrollAutomatico(datosAgenda, autoScroll);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 247, 250),
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Funciones.buildAppBar(
              urlFoto: globals.urlFoto,
              clave: globals.clave,
              nombreCompleto: globals.nombreCompleto,
              carrera: globals.carrera)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Agenda de Actividades",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 8, 50, 96),
                          ),
                          maxLines: 1,
                        ),
                      ),
                      Text(
                        "Ciclo escolar: ${globals.ciclo ?? '---'}",
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 12),
                      SizedBox(width: 4),
                      Text(
                        "Requisito de inscripción",
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (mensaje.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                mensaje,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.blueGrey, fontStyle: FontStyle.italic),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: const Color.fromARGB(255, 8, 50, 96),
              onRefresh: () async {
                Funciones.mantenerSesion(context);
                await Funciones.obtenerAgenda(datosAgenda, isLoading, setState, actualizaAgenda, actualizaMensaje);
              },
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: autoScroll,
                padding: const EdgeInsets.all(12),
                itemCount: datosAgenda.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = datosAgenda[index];
                  final fechaInicio = DateTime.parse(item['fecha_ini']);
                  final fechaFin = item['fecha_fin'] != null ? DateTime.parse(item['fecha_fin']) : null;
                  final now = DateTime.now();

                  Color colorBorde;
                  if (now.isBefore(fechaInicio)) {
                    colorBorde = Colors.blueAccent; // PRÓXIMAMENTE
                  } else if (fechaFin != null) {
                    if (now.isBefore(fechaFin)) {
                      colorBorde = Colors.green; // VIGENTE (en rango)
                    } else {
                      colorBorde = Colors.redAccent; // FINALIZADA
                    }
                  } else {
                    // Si no tiene fecha de fin y ya pasó su inicio -> ROJO
                    colorBorde = Colors.redAccent;
                  }

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: colorBorde.withValues(alpha: 0.5), width: 1),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => Actividad(item: item)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 5,
                              height: 50,
                              decoration: BoxDecoration(
                                color: colorBorde,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['titulo'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month_outlined, size: 14, color: Colors.grey),
                                      const SizedBox(width: 5),
                                      Text(
                                        Funciones.formatoFecha(item['fecha_ini']),
                                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (item['requisito'] == '1')
                              const Icon(Icons.warning, color: Colors.red, size: 20),
                            const Icon(Icons.chevron_right, color: Colors.grey),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCustomNavItem(
                  icon: Icons.calendar_month_outlined,
                  selectedIcon: Icons.calendar_month,
                  label: 'Agenda',
                  isSelected: true,
                  onTap: () {},
                ),
                _buildCustomNavItem(
                  icon: Icons.fact_check_outlined,
                  selectedIcon: Icons.fact_check,
                  label: 'Parciales',
                  isSelected: false,
                  onTap: () => Navigator.pushNamed(context, '/parciales'),
                ),
                _buildCustomNavItem(
                  icon: Icons.assignment_turned_in_outlined,
                  selectedIcon: Icons.assignment_turned_in,
                  label: 'Requisitos',
                  isSelected: false,
                  onTap: () {},
                ),
                _buildCustomNavItem(
                  icon: Icons.event_note_outlined,
                  selectedIcon: Icons.event_note,
                  label: 'Actividad',
                  isSelected: false,
                  onTap: () {},
                ),
                _buildCustomNavItem(
                  icon: Icons.logout_rounded,
                  selectedIcon: Icons.logout_rounded,
                  label: 'Salir',
                  isSelected: false,
                  isLogout: true,
                  onTap: () => _confirmarCierre(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLogout = false,
    // Tip: Pass BuildContext if you want to use Theme.of(context) here
  }) {
    const Color primaryColor = Color.fromARGB(255, 8, 50, 96);
    final Color activeColor = isLogout ? Colors.redAccent : primaryColor;
    final Color currentColor = isSelected ? activeColor : activeColor.withValues(alpha: 0.7);

    return Expanded(
      child: Padding(
        // Moved the margin out here so it doesn't interfere with the tap ripple
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? activeColor.withValues(alpha: 0.5) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      // Provide a key so AnimatedSwitcher knows when the icon changes
                      key: ValueKey<bool>(isSelected),
                      color: currentColor,
                      size: isSelected ? 26 : 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: currentColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarCierre(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              // Limpiar notificaciones de Firebase
              await Funciones.logoutFirebase();

              Funciones.editarSesion("0");
              SharedPreferences pref = await SharedPreferences.getInstance();
              await pref.clear();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const globals.LoginPage()), (route) => false);
            },
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );
  }
}
