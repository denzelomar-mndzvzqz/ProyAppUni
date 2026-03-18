// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fcq_app/main.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

class Funciones {
// Función encargada de construir el appBar de la aplicación
  static AppBar buildAppBar(
      {String? urlFoto,
      String? clave,
      String? nombreCompleto,
      String? carrera}) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 100,
      backgroundColor: const Color.fromARGB(255, 8, 50, 96),
      title: Row(
        children: [
          ClipOval(
            child: Image.network(
              urlFoto!,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // Los signos ?? (operador de fusión nula) proporcionan un valor de respaldo en caso de que el campo sea null
                clave ?? " ",
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              Text(
                nombreCompleto ?? " ",
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
              Text(
                carrera ?? " ",
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Función encargada de obtener la configuración de la app en la base de datos
  static Future<void> cargarDatos(
      BuildContext context,
      Function(void Function()) setStateCallback,
      Function(String) actualizaMensaje) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    try {
      final Uri url = Uri.parse(
          "https://fcq.uaslp.mx/secciones/api/obtener_conf.php"); //IP o Dominio

      final response = await http.get(url);

      var datos = json.decode(response.body);
      //print(response.body);

      if (datos['status'] == '0') {
        print("No se encontraron datos"); // Mostrar mensaje si no hay datos
        setStateCallback(() {
          actualizaMensaje(
            "**Error: no se ha podido conectar al servidor de la facultad**",
          ); // Actualiza el mensaje de error
        });
      } else {
        // Guarda los datos obtenidos en la app para usarse posteriormente aunque la app haya sido reiniciada
        await pref.setString('dir_ipv4', datos['ipv4']);
        await pref.setString('dir_foto', datos['url_foto']);
        await pref.setString('ciclo', datos['ciclo']);

        verificarSesion(context,
            setStateCallback); // Verificar la sesión después de cargar los datos
      }
    } catch (e) {
      print('Error al cargar datos: $e'); // Manejar errores
      setStateCallback(() {
        actualizaMensaje(
          "**Error: no se ha podido cargar los datos**",
        ); // Actualiza el mensaje de error
      });
    }
  }

// Función para verificar la sesión del usuario
  static Future<void> verificarSesion(
      BuildContext context, Function(void Function()) setStateCallback) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    ipv4 = pref.getString('dir_ipv4');
    urlFoto = pref.getString('dir_foto');
    ciclo = pref.getString('ciclo');

    final claveUnica = pref.getString('clave_unica');
    final contra = pref.getString('contrasena');

    final Uri url = Uri.parse("https://fcq.uaslp.mx/secciones/api/login.php");

    try {
      if (claveUnica != null) {
        final response = await http.post(url, body: {
          "clave_unica": claveUnica,
          "contrasena": contra,
        });

        var datosUsuario = json.decode(response.body);

        //Si el campo de la base de datos se encuentra en 1 inicia sesión sino limpia los datos del usuario almacenados
        if (datosUsuario['sesion_app'] == 1) {
          setStateCallback(() {
            ipv4 = pref.getString('dir_ipv4');
            clave = pref.getString('clave_unica');
            contrasena = pref.getString('contrasena');
            nombreCompleto = pref.getString('nombreCompleto');
            urlFoto = pref.getString('urlFoto');
            carrera = pref.getString('carrera');
          });

          Navigator.pushReplacementNamed(
              context, '/index'); // Redirigir al inicio
        } else {
          pref.clear(); // Limpiar datos de sesión si la sesión no está activa
          Navigator.pushReplacementNamed(
              context, '/login'); // Redirigir al inicio de sesión
        }
      }
    } catch (e) {
      print('Error al iniciar sesión verificarSesion(): $e'); // Manejar errores
      pref.clear(); // Limpiar datos de sesión si la sesión no está activa
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
  }

// Función para realizar el inicio de sesión y recibe la función que actualiza el mensaje
  static Future<List> login(
      String claveU,
      String contra,
      BuildContext context,
      Function(void Function()) setStateCallback,
      String mensaje,
      Function(String) actualizaMensaje) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    ipv4 = pref.getString('dir_ipv4');
    urlFoto = pref.getString('dir_foto');

    final Uri url = Uri.parse("https://fcq.uaslp.mx/secciones/api/login.php");

    try {
      final response = await http.post(url, body: {
        "clave_unica": claveU,
        "contrasena": contra,
      });

      var datosUsuario = json.decode(response.body);
      //print(response.body);

      if (datosUsuario['status'] == '0') {
        setStateCallback(() {
          actualizaMensaje(
            "**Clave o contraseña incorrectas**",
          ); // Actualiza el mensaje de error
        });
        return datosUsuario = [];
      } else {
        Navigator.pushReplacementNamed(
            context, '/index'); // Redirigir al inicio

        // Guarda los datos en variables globales y en la memoria de la aplicación
        setStateCallback(() {
          clave = datosUsuario['clave_unica'];
          contrasena = datosUsuario['contrasena'];
          nombreCompleto = datosUsuario['nombres'] +
              ' ' +
              datosUsuario['ape_pat'] +
              ' ' +
              datosUsuario['ape_mat'];
          urlFoto = urlFoto! + datosUsuario['foto'];
          carrera = datosUsuario['nombre_car'];
        });
        await pref.setString('clave_unica', clave!);
        await pref.setString('contrasena', contra);
        await pref.setString('nombreCompleto', nombreCompleto!);
        await pref.setString('urlFoto', urlFoto!);
        await pref.setString('carrera', carrera!);

        editarSesion(1.toString());

        return datosUsuario; // Editar la sesión del usuario en la Base de Datos
      }
    } catch (e) {
      print('Error al iniciar sesión login(): $e'); // Manejar errores
      return [];
    }
  }

// Función que recibe un 0 o un 1 para editar la sesión del usuario en la Base de Datos
  static Future<void> editarSesion(String n) async {
    final Uri url =
        Uri.parse("https://fcq.uaslp.mx/secciones/api/editar_sesion.php");

    try {
      await http.post(url, body: {
        "clave_unica": clave,
        "sesion_app": n,
      });
    } catch (e) {
      print('Error al editar sesión: $e'); // Manejar errores
    }
  }

// Función asincrónica para obtener datos de la agenda
  static Future<List<dynamic>> obtenerAgenda(
      List<dynamic> datosAgenda,
      bool isLoading,
      Function(void Function()) setStateCallback,
      Function(List<dynamic>, bool) actualizaAgenda,
      Function(String) actualizaMensaje) async {
    try {
      final Uri url =
          Uri.parse("https://fcq.uaslp.mx/secciones/api/obtener_agenda.php");

      final response = await http.post(url, body: {
        "ciclo": ciclo,
      });

      datosAgenda = json.decode(response.body);
      //print(response.body);

      if (datosAgenda[0]['status'] == '0') {
        setStateCallback(() {
          actualizaMensaje(
            "***No se han encontrado actividades***",
          ); // Actualiza el mensaje de error
        });
        return datosAgenda = [];
      } else {
        setStateCallback(() {
          datosAgenda.sort((a, b) {
            final fechaInicioA = DateTime.parse(a['fecha_ini']);
            final fechaInicioB = DateTime.parse(b['fecha_ini']);
            return fechaInicioA.compareTo(fechaInicioB);
          }); //Acomoda las actividades según la fecha de inicio

          isLoading = false;
          actualizaAgenda(datosAgenda,
              isLoading); // Hace uso de la función que actualiza el estado de la agenda en /index
        });

        return datosAgenda;
      }
    } catch (e) {
      setStateCallback(() {
        isLoading = true;
      });
      rethrow;
    }
  }

// Función que realiza una petición al servidor dónde se programan las actividades de la agenda
  static Future<void> programarNotificaciones() async {
    const url = 'https://fcq.uaslp.mx/secciones/api/notificaciones_app.php';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Notificaciones programadas con éxito');
      } else {
        print(
            'Error al programar notificaciones. Código de respuesta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error al realizar la solicitud HTTP: $e');
    }
  }

// Función para dar formato a las fechas en el idioma español
  static String formatoFecha(String dateString) {
    initializeDateFormatting('es');
    final inputFormat = DateFormat('yyyy-MM-dd');
    final outputFormat = DateFormat('dd ' 'MMMM' ' y', 'es');
    final date = inputFormat.parse(dateString);
    return outputFormat.format(date);
  }

// Función que se encarga de encontrar la actividad activa o futura y realiza scroll automático
  static ScrollController scrollAutomatico(
      List<dynamic> datosAgenda, ScrollController autoScroll) {
    // Ciclo que encuentra la fecha en curso o futura
    int actividadIndex = -1;
    for (int i = 0; i < datosAgenda.length; i++) {
      final item = datosAgenda[i];

      final fechaInicio = DateTime.parse(item['fecha_ini']);

      final fechaFin =
          item['fecha_fin'] != null ? DateTime.parse(item['fecha_fin']) : null;

      final esFechaPasadaNull =
          fechaFin == null && fechaInicio.isBefore(DateTime.now());

      final esFechaEnCurso = fechaInicio.isBefore(DateTime.now()) &&
          (fechaFin == null || fechaFin.isAfter(DateTime.now()));

      final esFechaFutura = fechaInicio.isAfter(DateTime.now());

      if (esFechaEnCurso && !esFechaPasadaNull) {
        actividadIndex = i;
        break;
      } else if (esFechaFutura) {
        actividadIndex = i;
        break;
      }
    }

    // Verifica si se encontró alguna fecha en curso o fecha futura y hace scroll automático
    if (actividadIndex != -1) {
      // Si es la primera actividad en curso o futura, hacer scroll hacia ella
      WidgetsBinding.instance.addPostFrameCallback((_) {
        autoScroll.animateTo(
          actividadIndex * //actividadIndex es el número de actividades que su fecha ya pasó
              100.0, // 100.0 es la altura de cada elemento
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }

    return autoScroll;
  }

// Función que se encarga de obtener los parciales del alumno en la sesión actual
  static Future<List<dynamic>> obtenerParciales(
      List<dynamic> parciales,
      bool isLoading,
      Function(void Function()) setStateCallback,
      Function(List<dynamic>, bool) actualizaParciales,
      Function(String) actualizaMensaje) async {
    try {
      final Uri url =
          Uri.parse("https://fcq.uaslp.mx/secciones/api/obtener_parciales.php");

      final response = await http.post(url, body: {
        "clave_unica": clave,
        "ciclo": ciclo,
      });

      Map<String, dynamic> jsonResponse = json.decode(response.body);
      print(response.body);

      if (jsonResponse['status'] == '0') {
        setStateCallback(() {
          actualizaMensaje(
            "**No se han encontrado parciales**",
          ); // Actualiza el mensaje de error
          isLoading = false;
          actualizaParciales(parciales, isLoading);
        });
        return parciales = [];
      } else {
        parciales = jsonResponse['parciales'];
        setStateCallback(() {
          isLoading = false;
          actualizaParciales(parciales, isLoading);
        });

        return parciales;
      }
    } catch (e) {
      setStateCallback(() {
        isLoading = true;
      });
      print('Error en obtenerParciales: $e');
      rethrow;
    }
  }

  static Future<void> mantenerSesion(BuildContext context) async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    final claveUnica = pref.getString('clave_unica');
    final contra = pref.getString('contrasena');

    final Uri url = Uri.parse("https://fcq.uaslp.mx/secciones/api/login.php");

    try {
      if (claveUnica != null) {
        final response = await http.post(url, body: {
          "clave_unica": claveUnica,
          "contrasena": contra,
        });

        var datosUsuario = json.decode(response.body);

        //Si el campo de la base de datos se encuentra en 1 inicia sesión sino limpia los datos del usuario almacenados
        if (datosUsuario['sesion_app'] == 1) {
          print("sesión activa");
        } else {
          pref.clear(); // Limpiar datos de sesión si la sesión no está activa
          Navigator.pushReplacementNamed(
              context, '/login'); // Redirigir al inicio de sesión
        }
      }
    } catch (e) {
      print('Error al iniciar sesión mantenerSesion(): $e'); // Manejar errores
      pref.clear(); // Limpiar datos de sesión si la sesión no está activa
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
  }
}
