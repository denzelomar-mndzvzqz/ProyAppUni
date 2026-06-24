// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:convert';
import 'dart:async';

import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fcq_app/main.dart' as globals;
import 'package:fcq_app/main.dart'; // Añadido para acceder a navigatorKey
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// --- CAPA DE MODELOS ---
class Usuario {
  final String claveUnica;
  final String nombreCompleto;
  final String carrera;
  final String urlFoto;
  final String ciclo;

  Usuario({
    required this.claveUnica,
    required this.nombreCompleto,
    required this.carrera,
    required this.urlFoto,
    required this.ciclo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json, String baseUrlFoto, String defaultCiclo) {
    return Usuario(
      claveUnica: json['clave_unica']?.toString() ?? '',
      nombreCompleto: '${json['nombres'] ?? ""} ${json['ape_pat'] ?? ""} ${json['ape_mat'] ?? ""}'.trim(),
      carrera: json['nombre_car']?.toString() ?? '',
      urlFoto: baseUrlFoto + (json['foto'] ?? ''),
      ciclo: json['ciclo']?.toString() ?? defaultCiclo,
    );
  }
}

/// --- CAPA DE SERVICIO API ---
class ApiService {
  // Ya no usamos un cliente estático para evitar persistencia de sesiones/cookies
  static http.Client _getFreshClient() {
    final HttpClient innerClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..badCertificateCallback = ((cert, host, port) => true);
    return IOClient(innerClient);
  }

  /// Petición unificada con cliente fresco para evitar reutilización de sesiones
  static Future<http.Response> request(String url, {required String method, Map<String, String>? params, Map<String, String>? body}) async {
    final http.Client client = _getFreshClient();
    try {
      Uri uri = Uri.parse(url);

      // Cache busting más agresivo en la URL
      final String separator = url.contains('?') ? '&' : '?';
      uri = Uri.parse("$url${separator}nocache=${DateTime.now().microsecondsSinceEpoch}");

      if (params != null) {
        uri = uri.replace(queryParameters: {...uri.queryParameters, ...params});
      }

      print('🌐 Request [$method]: $uri');

      final Map<String, String> headers = {
        "User-Agent": "ProyAppUni/1.2",
        "Accept": "application/json",
        "Cache-Control": "no-cache, no-store, must-revalidate",
        "Pragma": "no-cache",
        "Expires": "0",
        "Connection": "close",
      };

      http.Response response;
      if (method == 'GET') {
        response = await client.get(uri, headers: headers).timeout(const Duration(seconds: 12));
      } else {
        headers["Content-Type"] = "application/x-www-form-urlencoded";
        // Añadimos cache-buster al cuerpo si es POST
        final Map<String, String> fullBody = body != null ? Map<String, String>.from(body) : {};
        fullBody['cache_bust'] = DateTime.now().millisecondsSinceEpoch.toString();

        response = await client.post(uri, headers: headers, body: fullBody).timeout(const Duration(seconds: 12));
      }
      return response;
    } finally {
      client.close(); // Cerramos el cliente inmediatamente
    }
  }
}

/// --- CAPA DE FUNCIONES (Coordinador) ---
class Funciones {
  static String? clave;
  static String? contrasena;
  static String? nombreCompleto;
  static String? urlFoto;
  static String? carrera;
  static String? ciclo;
  static String? ipv4;

  static AppBar buildAppBar({String? urlFoto, String? clave, String? nombreCompleto, String? carrera}) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 100,
      backgroundColor: const Color.fromARGB(255, 8, 50, 96),
      title: Row(
        children: [
          ClipOval(
            child: (urlFoto != null && urlFoto.isNotEmpty)
                ? Image.network(
              urlFoto,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 70, color: Colors.white),
            )
                : const Icon(Icons.person, size: 70, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(clave ?? " ", style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                Text(nombreCompleto ?? " ", style: const TextStyle(fontSize: 11, color: Colors.white), overflow: TextOverflow.ellipsis),
                Text(carrera ?? " ", style: const TextStyle(fontSize: 10, color: Colors.white70), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white, size: 30),
          onPressed: () => navigatorKey.currentState?.pushNamed('/notificaciones'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  static Future<void> cargarDatos(BuildContext context, Function(void Function()) setStateCallback, Function(String) actualizaMensaje) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    try {
      final response = await ApiService.request("https://fcq.uaslp.mx/secciones/api/obtener_conf.php", method: 'GET');

      if (response.body.trim().isEmpty) {
        throw const FormatException("Respuesta vacía del servidor");
      }

      var datos = json.decode(response.body);

      if (datos['status'].toString() != '0') {
        await pref.setString('dir_ipv4', datos['ipv4'] ?? '');
        await pref.setString('dir_foto', datos['url_foto'] ?? '');
        await pref.setString('ciclo', datos['ciclo'] ?? '');
        await pref.setString('url_php', datos['url_php'] ?? '');

        Funciones.ciclo = datos['ciclo'];
        Funciones.ipv4 = datos['ipv4'];

        // RESTAURADO: Verificamos sesión automáticamente para permitir auto-login
        await verificarSesion(context, setStateCallback);
      }
    } catch (e) {
      print('Error en cargarDatos: $e');
      actualizaMensaje("**Error de conexión inicial**");
    }
  }

  static Future<void> verificarSesion(BuildContext context, Function(void Function()) setStateCallback, {bool redireccionar = true}) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final cU = pref.getString('clave_unica');
    final cP = pref.getString('contrasena');
    final storedCiclo = pref.getString('ciclo');
    final urlPhp = pref.getString('url_php');

    if (cU == null || cP == null) return;

    String baseUrl = (urlPhp != null && urlPhp.isNotEmpty) ? "${urlPhp}login.php" : "https://fcq.uaslp.mx/secciones/api/login.php";

    try {
      final payload = {"clave_unica": cU, "contrasena": cP, "ciclo": storedCiclo ?? ""};
      // Intentamos GET primero y luego POST como respaldo
      http.Response response = await ApiService.request(baseUrl, method: 'GET', params: payload);
      var res = json.decode(response.body);

      if (_esRespuestaFallida(res)) {
        response = await ApiService.request(baseUrl, method: 'POST', body: payload);
        res = json.decode(response.body);
      }

      if (!_esRespuestaFallida(res)) {
        Map<String, dynamic> datosJson = (res is List) ? res[0] : res;
        Usuario user = Usuario.fromJson(datosJson, pref.getString('dir_foto') ?? '', storedCiclo ?? '');

        setStateCallback(() {
          Funciones.clave = user.claveUnica;
          Funciones.contrasena = cP;
          Funciones.nombreCompleto = user.nombreCompleto;
          Funciones.urlFoto = user.urlFoto;
          Funciones.carrera = user.carrera;
          Funciones.ciclo = user.ciclo;

          // Sincronizar con variables globales de main.dart
          globals.clave = user.claveUnica;
          globals.contrasena = cP;
          globals.nombreCompleto = user.nombreCompleto;
          globals.urlFoto = user.urlFoto;
          globals.carrera = user.carrera;
          globals.ciclo = user.ciclo;
        });

        // SINCRONIZAR TOKEN CON EL SERVIDOR
        await registrarTokenServidor(user.claveUnica);

        if (redireccionar && (ModalRoute.of(context)?.settings.name == '/' || ModalRoute.of(context)?.settings.name == '/login')) {
          Navigator.pushReplacementNamed(context, '/index');
        }
      }
    } catch (e) {
      print('Error verificarSesion: $e');
    }
  }

  static Future<dynamic> login(String claveU, String contra, BuildContext context, Function(void Function()) setStateCallback, String mensaje, Function(String) actualizaMensaje) async {
    if (claveU.isEmpty || contra.isEmpty) {
      actualizaMensaje("Ingresa clave y contraseña");
      return [];
    }

    SharedPreferences pref = await SharedPreferences.getInstance();

    // 1. LIMPIEZA TOTAL: Borramos disco y variables de estado antes de intentar
    await pref.clear();
    await pref.commit();

    // Reseteo forzado de variables para evitar que se "reusen" datos viejos
    Funciones.clave = null;
    Funciones.contrasena = null;
    Funciones.nombreCompleto = null;
    globals.clave = null;
    globals.contrasena = null;
    globals.nombreCompleto = null;

    // 1.5 LOGOUT PREVENTIVO: Intentamos cerrar cualquier sesión fantasma en el servidor
    try {
      await ApiService.request("https://fcq.uaslp.mx/secciones/api/editar_sesion.php",
          method: 'POST', body: {"clave_unica": claveU.trim(), "sesion_app": "0"});
    } catch (_) {}

    // 2. RECARGAR CONFIGURACIÓN
    final responseConf = await ApiService.request("https://fcq.uaslp.mx/secciones/api/obtener_conf.php", method: 'GET');
    var dC = json.decode(responseConf.body);

    // GUARDAR CONFIGURACIÓN CRÍTICA: Re-almacenamos las URLs necesarias tras el clear()
    await pref.setString('dir_foto', dC['url_foto'] ?? '');
    await pref.setString('url_php', dC['url_php'] ?? '');
    await pref.setString('ciclo', dC['ciclo'] ?? '');

    Funciones.ciclo = dC['ciclo'];
    String baseUrl = "${dC['url_php'] ?? "https://fcq.uaslp.mx/secciones/api/"}login.php";
    actualizaMensaje("Validando con el servidor...");

    try {
      final Map<String, String> payload = {
        "clave_unica": claveU.trim(),
        "contrasena": contra,
        "ciclo": dC['ciclo'] ?? "2024-2025/II",
      };

      // 3. INTENTO POR POST (Más estricto)
      print('DEBUG: Enviando Clave: $claveU, Contra: ${"*" * contra.length}');

      http.Response response = await ApiService.request(baseUrl, method: 'POST', body: payload);
      var res = json.decode(response.body);

      // LOG DE RESPUESTA PARA DEPURAR
      print('📥 Respuesta Servidor Login: $res');

      if (_esRespuestaFallida(res)) {
        actualizaMensaje("**Credenciales incorrectas**");
        return [];
      }

      Map<String, dynamic> datosJson = (res is List) ? res[0] : res;

      // 4. CANDADO DE SEGURIDAD LOCAL (Anti-Bypass del Servidor)
      // Si el servidor devolvió éxito pero la contraseña enviada era incorrecta,
      // el servidor tiene un fallo de sesión. Forzamos el cierre.
      if (datosJson['status'].toString() == '1' && datosJson['clave_unica'].toString() != claveU.trim()) {
        print("🚨 ALERTA: El servidor devolvió datos de otro alumno (${datosJson['clave_unica']})");
        actualizaMensaje("**Error de sincronización del servidor. Reintenta.**");
        await ApiService.request("https://fcq.uaslp.mx/secciones/api/editar_sesion.php", method: 'POST', body: {"clave_unica": datosJson['clave_unica'].toString(), "sesion_app": "0"});
        return [];
      }

      Usuario user = Usuario.fromJson(datosJson, pref.getString('dir_foto') ?? '', dC['ciclo'] ?? '');

      setStateCallback(() {
        Funciones.clave = user.claveUnica;
        Funciones.contrasena = contra;
        Funciones.nombreCompleto = user.nombreCompleto;
        Funciones.urlFoto = user.urlFoto;
        Funciones.carrera = user.carrera;
        Funciones.ciclo = user.ciclo;

        // Sincronizar con variables globales de main.dart
        globals.clave = user.claveUnica;
        globals.contrasena = contra;
        globals.nombreCompleto = user.nombreCompleto;
        globals.urlFoto = user.urlFoto;
        globals.carrera = user.carrera;
        globals.ciclo = user.ciclo;
      });

      await pref.setString('clave_unica', user.claveUnica);
      await pref.setString('contrasena', contra);
      await pref.setString('nombreCompleto', user.nombreCompleto);
      await pref.setString('urlFoto', user.urlFoto);
      await pref.setString('carrera', user.carrera);
      await pref.setString('ciclo', user.ciclo);

      // RE-ACTIVAR NOTIFICACIONES AL LOGUEAR
      await FirebaseMessaging.instance.subscribeToTopic('Actividades');
      
      // SINCRONIZAR TOKEN CON EL SERVIDOR
      await registrarTokenServidor(user.claveUnica);

      await editarSesion("1");
      Navigator.pushReplacementNamed(context, '/index');
      return res;

    } catch (e) {
      print('🔥 Error login: $e');
      actualizaMensaje("**Mantenimiento del servidor: Intenta en un momento**");
      return [];
    }
  }

  static bool _esRespuestaFallida(dynamic res) {
    if (res == null) return true;
    if (res is List && res.isEmpty) return true;

    // Extraemos el status y la clave única para validar
    var primerRegistro = (res is List) ? res[0] : res;
    var status = primerRegistro['status'];

    // Si el status es 0, es fallo obvio
    if (status.toString() == '0') return true;

    // Si el status es 1 pero no trae clave_unica, es una respuesta incompleta/mock
    if (primerRegistro['clave_unica'] == null) return true;

    return false;
  }

  static Future<void> editarSesion(String n) async {
    try {
      await ApiService.request("https://fcq.uaslp.mx/secciones/api/editar_sesion.php", method: 'POST', body: {
        "clave_unica": clave ?? "",
        "sesion_app": n,
      });
    } catch (e) {
      print('Error editarSesion: $e');
    }
  }

  // RESTAURACIÓN DE MÉTODOS PARA COMPATIBILIDAD
  static Future<void> mantenerSesion(BuildContext context) async {
    await verificarSesion(context, (_) {});
  }

  static Future<List<dynamic>> obtenerAgenda(
      List<dynamic> datosAgenda, bool isLoading, Function(void Function()) setStateCallback,
      Function(List<dynamic>, bool) actualizaAgenda, Function(String) actualizaMensaje) async {
    try {
      if (ciclo == null || ciclo!.isEmpty) {
        SharedPreferences pref = await SharedPreferences.getInstance();
        ciclo = pref.getString('ciclo');
      }

      // Revertimos a enviar solo el ciclo, ya que el servidor parece usar sesión interna
      final payload = {"ciclo": ciclo ?? ""};

      http.Response response = await ApiService.request("https://fcq.uaslp.mx/secciones/api/obtener_agenda.php", method: 'POST', body: payload);
      var decoded = json.decode(response.body);

      if (_esRespuestaFallida(decoded)) {
        response = await ApiService.request("https://fcq.uaslp.mx/secciones/api/obtener_agenda.php", method: 'GET', params: payload);
        decoded = json.decode(response.body);
      }

      List<dynamic> agenda = (decoded is List) ? decoded : [];

      if (agenda.isEmpty || (agenda.isNotEmpty && agenda[0]['status'].toString() == '0')) {
        actualizaMensaje("***No se han encontrado actividades***");
        actualizaAgenda([], false);
        return [];
      } else {
        agenda.sort((a, b) => (a['fecha_ini'] ?? "").compareTo(b['fecha_ini'] ?? ""));
        actualizaAgenda(agenda, false);
        actualizaMensaje(""); // Limpiamos mensaje si hay datos
        return agenda;
      }
    } catch (e) {
      print("Error obtenerAgenda: $e");
      actualizaAgenda([], false);
      return [];
    }
  }

  static Future<List<dynamic>> obtenerParciales(
      List<dynamic> parciales, bool isLoading, Function(void Function()) setStateCallback,
      Function(List<dynamic>, bool) actualizaParciales, Function(String) actualizaMensaje) async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();

      // Aseguramos que la clave y el ciclo estén disponibles (recuperamos de pref si es necesario)
      String? cU = clave ?? pref.getString('clave_unica');
      String? cI = ciclo ?? pref.getString('ciclo');

      if (cU == null || cU.isEmpty) {
        actualizaMensaje("**Error: No se encontró la sesión del alumno**");
        actualizaParciales([], false);
        return [];
      }

      final payload = {
        "clave_unica": cU,
        "ciclo": cI ?? "2024-2025/II"
      };

      print("📡 Solicitando parciales para $cU en el ciclo $cI");

      // 1. Intentamos con POST
      http.Response response = await ApiService.request(
          "https://fcq.uaslp.mx/secciones/api/obtener_parciales.php",
          method: 'POST',
          body: payload
      );

      // 2. Si el servidor responde vacío, intentamos con GET (Fallback)
      if (response.body.trim().isEmpty) {
        print("⚠️ POST vacío en parciales, intentando GET...");
        response = await ApiService.request(
            "https://fcq.uaslp.mx/secciones/api/obtener_parciales.php",
            method: 'GET',
            params: payload
        );
      }

      if (response.body.trim().isEmpty) {
        actualizaMensaje("**Servidor en mantenimiento**");
        actualizaParciales([], false);
        return [];
      }

      var decoded = json.decode(response.body);
      List<dynamic> lista = [];

      // LÓGICA DE EXTRACCIÓN ROBUSTA
      if (decoded is List) {
        if (decoded.isNotEmpty) {
          // Si el primer elemento tiene 'nombre_mat', la lista misma contiene las materias
          if (decoded[0] is Map && (decoded[0] as Map).containsKey('nombre_mat')) {
            lista = decoded;
          }
          // Si es una lista que contiene un objeto con la clave 'parciales'
          else if (decoded[0] is Map && (decoded[0] as Map).containsKey('parciales')) {
            lista = decoded[0]['parciales'] ?? [];
          }
        }
      } else if (decoded is Map) {
        // Si es un objeto directo con la clave 'parciales' o 'data'
        lista = decoded['parciales'] ?? decoded['data'] ?? [];
      }

      if (lista.isEmpty) {
        // Verificamos si hay un mensaje de error o status 0 explícito
        var status = (decoded is Map) ? decoded['status'] : (decoded is List && decoded.isNotEmpty ? decoded[0]['status'] : null);
        if (status.toString() == '0') {
          actualizaMensaje("**No se han encontrado parciales registrados**");
        } else {
          actualizaMensaje("**Aún no hay calificaciones cargadas**");
        }
        actualizaParciales([], false);
        return [];
      } else {
        actualizaMensaje(""); // Éxito, limpiamos mensajes
        actualizaParciales(lista, false);
        return lista;
      }
    } catch (e) {
      print("🔥 Error crítico en obtenerParciales: $e");
      actualizaMensaje("**Error al conectar con el servidor de parciales**");
      actualizaParciales([], false);
      return [];
    }
  }

  /// Realiza una petición al servidor para programar o actualizar las notificaciones
  /// de las actividades de la agenda.
  static Future<void> programarNotificaciones() async {
    const String url = 'https://fcq.uaslp.mx/secciones/api/notificaciones_app.php';
    try {
      final response = await ApiService.request(url, method: 'GET');

      if (response.statusCode == 200) {
        print('🔔 Notificaciones: Programadas con éxito');
      } else {
        print('🔔 Notificaciones: Error del servidor (Código: ${response.statusCode})');
      }
    } catch (e) {
      print('🔔 Notificaciones: Error de conexión: $e');
    }
  }

  static String formatoFecha(String dateString) {
    try {
      initializeDateFormatting('es');
      final date = DateFormat('yyyy-MM-dd').parse(dateString);
      return DateFormat('dd MMMM y', 'es').format(date);
    } catch (e) {
      return dateString;
    }
  }

  /// Limpia la sesión de Firebase al cerrar sesión en el app.
  /// Desuscribe del tema.
  static Future<void> logoutFirebase() async {
    try {
      // 1. Desuscribirse del tema de actividades (Evita notificaciones masivas)
      await FirebaseMessaging.instance.unsubscribeFromTopic('Actividades');

      // NOTA: Ya no borramos el token con deleteToken() para evitar retrasos de propagación.
      // El token permanece igual, pero el dispositivo deja de pertenecer al tema.

      print('🔔 Firebase: Sesión cerrada y desuscripción de temas exitosa');
    } catch (e) {
      print('⚠️ Error al desactivar notificaciones en Firebase: $e');
    }
  }

  static ScrollController scrollAutomatico(List<dynamic> datosAgenda, ScrollController autoScroll) {
    int index = datosAgenda.indexWhere((item) {
      final inicio = DateTime.tryParse(item['fecha_ini'] ?? "");
      return inicio != null && inicio.isAfter(DateTime.now().subtract(const Duration(days: 1)));
    });
    if (index != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (autoScroll.hasClients) {
          autoScroll.animateTo(index * 100.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      });
    }
    return autoScroll;
  }

  /// Envía el token de Firebase al servidor para notificaciones INDIVIDUALES
  static Future<void> registrarTokenServidor(String claveUnica) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? token = pref.getString('dispositivo_token'); 

    if (token != null && token.isNotEmpty) {
      try {
        final payload = {
          "clave_unica": claveUnica,
          "token": token,
          "sesion_app": "1",
        };

        // Enviamos por AMBOS métodos (Params para GET y Body para POST)
        // para asegurar compatibilidad total con el script PHP
        final response = await ApiService.request(
            "https://fcq.uaslp.mx/secciones/api/editar_sesion.php",
            method: 'POST',
            params: payload, // Esto viaja en la URL (?token=...)
            body: payload    // Esto viaja en el cuerpo del mensaje
        );
        print('✅ Token y sesión sincronizados para la clave $claveUnica (Dual Method)');
        print('📥 RESPUESTA DEL SERVIDOR: ${response.body}');
      } catch (e) {
        print('⚠️ Error al registrar token en el servidor: $e');
      }
    }
  }
}
