// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:fcq_app/main.dart';
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

  //Función que asegura que la agenda se actualice para mostrar correctamente
  void actualizaAgenda(List<dynamic> agenda, bool L) {
    setState(() {
      datosAgenda = agenda;
      isLoading = L;
    });
  }

  //Función que asegura que la agenda se actualice para mostrar correctamente
  void actualizaMensaje(String nuevoMensaje) {
    setState(() {
      mensaje = nuevoMensaje;
    });
  }

  @override
  void initState() {
    // Función que se ejecuta antes de construir la pantalla
    super.initState();
    isLoading = true;
    Funciones.obtenerAgenda(
        datosAgenda, isLoading, setState, actualizaAgenda, actualizaMensaje);
    Funciones.programarNotificaciones();
  }

  @override
  Widget build(BuildContext context) {
    autoScroll = Funciones.scrollAutomatico(datosAgenda, autoScroll);

    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Funciones.buildAppBar(
              urlFoto: urlFoto,
              clave: clave,
              nombreCompleto: nombreCompleto,
              carrera: carrera)),
      body: Column(
        children: [
          Container(
            // Barra superior que indica el significado del icono warning
            padding: const EdgeInsets.all(10.0),
            color: const Color.fromARGB(255, 218, 218, 218),
            child: const Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Color.fromARGB(255, 252, 17, 0),
                    ),
                    SizedBox(width: 8),
                    Text("Requisito de inscripción"),
                  ],
                ),
              ],
            ),
          ),
          Visibility(
              visible: mensaje.isNotEmpty,
              child: Text(
                // Mensaje de error en caso de no encontrar actividades
                mensaje,
                style: const TextStyle(fontSize: 25.0, color: Colors.red),
              )),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                Funciones.mantenerSesion(context);
                // Llama a las funciones que necesiten actualizarse al hacer refresh en la app
                await Funciones.obtenerAgenda(datosAgenda, isLoading, setState,
                    actualizaAgenda, actualizaMensaje);
              },
              child: SizedBox(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: autoScroll,
                        itemCount: datosAgenda.length,
                        itemBuilder: (BuildContext context, int index) {
                          final item = datosAgenda[index];
                          // Define las fechas en formato DateTime para posteriormente asignar un color a cada actividad segun las fechas
                          final fechaInicio = DateTime.parse(item['fecha_ini']);
                          final fechaFin = item['fecha_fin'] != null
                              ? DateTime.parse(item['fecha_fin'])
                              : null;

                          final esFechaPasada = fechaFin != null &&
                              fechaFin.isBefore(DateTime.now());
                          final esFechaEnCurso =
                              fechaInicio.isBefore(DateTime.now()) &&
                                  (fechaFin == null ||
                                      fechaFin.isAfter(DateTime.now()));
                          final esFechaPasadaNull = fechaFin == null &&
                              fechaInicio.isBefore(DateTime.now());

                          Color
                              colorActividad; //Variable que almacena el color de la actividad que se mostrará según la fecha

                          if (esFechaPasada || esFechaPasadaNull) {
                            colorActividad = const Color.fromRGBO(
                                252, 111, 111, 1.0); // Rojo
                          } else if (esFechaEnCurso) {
                            colorActividad = const Color.fromRGBO(
                                110, 192, 120, 1.0); // Verde
                          } else {
                            colorActividad = const Color.fromRGBO(
                                110, 192, 252, 1.0); // Azul
                          }

                          return SizedBox(
                            height:
                                100, // Establece la altura deseada para cada elemento
                            child: InkWell(
                              onTap: () {
                                // Navegar a otra pantalla con más información sobre la actividad
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Actividad(item: item),
                                  ),
                                );
                              },
                              child: Card(
                                color: colorActividad,
                                child: ListTile(
                                  title: Text(item['titulo']),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Text(
                                        // Formatea la fecha
                                        ' ${Funciones.formatoFecha(item['fecha_ini'])}${item['fecha_fin'] != null ? ' a ${Funciones.formatoFecha(item['fecha_fin'])}' : ''}',
                                      ),
                                    ],
                                  ),
                                  trailing: item['requisito'] ==
                                          1
                                              .toString() // Muestra el icóno Danger según los datos del campo requisito de la BD
                                      ? const Icon(Icons.warning,
                                          color:
                                              Color.fromARGB(255, 252, 17, 0))
                                      : const Visibility(
                                          visible: false,
                                          child: Icon(Icons.warning,
                                              color: Colors.transparent),
                                        ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        // Barra inferior que permite navegar a más pantallas
        child: Row(
          children: <Widget>[
            // *Agregar más elementos al bottomNavigationBar si es necesario
            IconButton(
              icon: const Icon(Icons.description), //Icono de descripción
              onPressed: () {
                Navigator.pushNamed(context, '/parciales');
              },
            ),
            IconButton(
              icon: const Icon(Icons.web_asset), //Icono de descripción
              onPressed: () {
                Navigator.pushNamed(context, '/info');
              },
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.logout), // Icono de cerrar sesión
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Cerrar Sesión'),
                      content: const Text('¿Seguro que quieres cerrar sesión?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () async {
                            // Cerrar sesión
                            Funciones.editarSesion(0.toString());
                            SharedPreferences pref =
                                await SharedPreferences.getInstance();
                            await pref
                                .clear(); // Borra todos los datos de SharedPreferences

                            // Navegar de regreso a la pantalla de inicio de sesión
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LoginPage(), // Regresa a la pantalla de inicio de sesión
                              ),
                              (route) =>
                                  false, // Esta función evita que el usuario pueda volver atrás una vez cerrada la sesión
                            );
                          },
                          child: const Text('Aceptar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(); // Cierra el cuadro de diálogo
                          },
                          child: const Text('Cancelar'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
