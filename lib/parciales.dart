// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:fcq_app/main.dart' as globals;
import 'package:fcq_app/funciones.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Parciales extends StatefulWidget {
  const Parciales({super.key});

  @override
  _Parcial createState() => _Parcial();
}

class _Parcial extends State<Parciales> {
  String mensaje = '';
  List<dynamic> parciales = [];
  bool isLoading = false;

  //Función que asegura que la lista de materias (parciales) se actualice para mostrar correctamente
  void actualizaParciales(List<dynamic> parcial, bool L) {
    setState(() {
      parciales = parcial;
      isLoading = L;
    });
  }

  //Función que actualiza el mensaje en caso de que la clave o contraseña sean incorrectos
  void actualizaMensaje(String nuevoMensaje) {
    setState(() {
      mensaje = nuevoMensaje;
    });
  }

  @override
  void initState() {
    super.initState();
    isLoading = true;
    Funciones.obtenerParciales(
        parciales, isLoading, setState, actualizaParciales, actualizaMensaje);
    Funciones.mantenerSesion(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Funciones.buildAppBar(
              urlFoto: globals.urlFoto,
              clave: globals.clave,
              nombreCompleto: globals.nombreCompleto,
              carrera: globals.carrera)),
      body: Column(children: [
        Visibility(
            visible: mensaje.isNotEmpty,
            child: Text(
              // Mensaje de error en caso de no encontrar actividades
              mensaje,
              style: const TextStyle(fontSize: 25.0, color: Colors.red),
            )),
        Expanded(
            child: SizedBox(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: parciales.length,
                itemBuilder: (context, index) {
                  final parcial = parciales[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parcial['nombre_mat'] ?? 'Materia sin nombre',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color.fromARGB(255, 8, 50, 96),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Profesor: ${parcial['nombre_pro'] ?? 'No especificado'}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const Divider(height: 24),
                          // Mostramos los datos disponibles de forma dinámica
                          _buildCalificacionesSimples(parcial),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )),
      ]),
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
                  isSelected: false,
                  onTap: () => Navigator.pushReplacementNamed(context, '/index'),
                ),
                _buildCustomNavItem(
                  icon: Icons.fact_check_outlined,
                  selectedIcon: Icons.fact_check,
                  label: 'Parciales',
                  isSelected: true,
                  onTap: () {},
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

  Widget _buildCalificacionesSimples(Map<String, dynamic> data) {
    // Esta función mostrará de forma dinámica cualquier dato que venga en el JSON
    // exceptuando los nombres de materia y profesor que ya mostramos arriba.
    final keysToIgnore = ['nombre_mat', 'nombre_pro', 'status', 'clave_unica'];

    List<Widget> rows = [];
    data.forEach((key, value) {
      if (!keysToIgnore.contains(key) && value != null && value.toString().isNotEmpty) {
        rows.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  key.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      }
    });

    return Column(children: rows);
  }
}
