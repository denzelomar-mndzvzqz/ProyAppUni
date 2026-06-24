// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:fcq_app/firebase_api.dart';
import 'package:fcq_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:fcq_app/index.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fcq_app/funciones.dart';
import 'package:fcq_app/parciales.dart';
import 'package:fcq_app/notificaciones_service.dart';
import 'package:fcq_app/notificaciones_page.dart';

// Clave global para el navigatorKey, que permite la navegación en toda la aplicación
final navigatorKey = GlobalKey<NavigatorState>();

// Función obligatoria para manejar mensajes en segundo plano (debe estar fuera de cualquier clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // GUARDAR EN EL HISTORIAL TAMBIÉN EN SEGUNDO PLANO
  if (message.notification != null) {
    await NotificacionesService.guardarNotificacion(
      message.notification!.title ?? 'Sin título',
      message.notification!.body ?? '',
    );
  }

  print("HOLA desde el segundo plano: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Registrar el manejador de segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // No esperamos a las notificaciones para arrancar la App
  FirebaseApi().iniNotificacion();

  runApp(const LoginApp());
}

// Declaración de variables globales
String? clave;
String? contrasena;
String? nombreCompleto;
String? ipv4;
String? urlFoto;
String? carrera;
String? ciclo;

// Clase principal de la aplicación Flutter donde se definen las rutas
class LoginApp extends StatelessWidget {
  const LoginApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
      ),
      title: 'FCQ',
      home: const LoginPage(),
      navigatorKey: navigatorKey,
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => const LoginPage(),
        '/index': (BuildContext context) => const Home(),
        '/parciales': (BuildContext context) => const Parciales(),
        '/notificaciones': (BuildContext context) => const NotificacionesPage(),
      },
    );
  }
}

// Clase para la página de inicio de sesión
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controladores para los campos de clave y contraseña
  final _claveController = TextEditingController();
  final _contraController = TextEditingController();

  String mensaje = ''; // Mensaje para mostrar errores de inicio de sesión
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    Funciones.cargarDatos(context,
        setState, actualizaMensaje); // Cargar la configuración de la aplicación al iniciar
  }
  //Función que actualiza el mensaje en caso de que la clave o contraseña sean incorrectos
  void actualizaMensaje(String nuevoMensaje) {
    setState(() {
      mensaje = nuevoMensaje;
    });
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              height: MediaQuery.of(context).size.height * 0.4,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 8, 50, 96),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
                  child: Image.asset(
                    'assets/img/uaslp_logo_clean.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),
                  const Text(
                    "Bienvenido",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 8, 50, 96),
                    ),
                  ),
                  const Text(
                    "Ingresa tus credenciales para continuar",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _claveController,
                    decoration: InputDecoration(
                      labelText: 'Clave Única',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _contraController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _intentarLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 8, 50, 96),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'INICIAR SESIÓN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),
                  if (mensaje.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      mensaje,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.blueGrey, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _intentarLogin() async {
    setState(() {
      _isLoading = true;
      actualizaMensaje("");
    });
    try {
      await Funciones.login(
          _claveController.text.trim(),
          _contraController.text,
          context,
          setState,
          mensaje,
          actualizaMensaje);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
