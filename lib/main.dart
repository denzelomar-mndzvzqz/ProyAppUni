// ignore_for_file: use_build_context_synchronously, avoid_print

import 'package:fcq_app/firebase_api.dart';
import 'package:fcq_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:fcq_app/index.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fcq_app/funciones.dart';
import 'package:fcq_app/parciales.dart';
import 'package:fcq_app/info.dart';

// Clave global para el navigatorKey, que permite la navegación en toda la aplicación
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi().iniNotificacion();
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
      title: 'FCQ',
      home: const LoginPage(),
      navigatorKey: navigatorKey,
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => const LoginPage(),
        '/index': (BuildContext context) => const Home(),
        '/parciales': (BuildContext context) => const Parciales(),
        '/info': (BuildContext context) => const Info(),
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
      resizeToAvoidBottomInset: false,
      body: Form(
        child: Column(
          children: <Widget>[
            Container(
              // Imagen del login
              padding: const EdgeInsets.only(top: 100),
              child: Image.asset(
                'assets/img/logoUASLP.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            Container(
              //Container del formulario
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    // Campo para ingresar la clave única
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextFormField(
                      controller: _claveController,
                      decoration: const InputDecoration(
                        labelText: 'Clave Única',
                      ),
                    ),
                  ),
                  SizedBox(
                    // Campo para ingresar la contraseña
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextFormField(
                      controller: _contraController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Center(
                    // Botón para el inicio de sesión
                    child: ElevatedButton(
                      onPressed: () {
                        Funciones.login(
                            _claveController.text,
                            _contraController.text,
                            context,
                            setState,
                            mensaje,
                            actualizaMensaje); // Llamar a la función de inicio de sesión
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 8, 50, 96),
                      ),
                      child: const Text('Iniciar Sesión'),
                    ),
                  ),
                  Text(
                    // Mensaje de error en caso de clave o contrseña incorrectos
                    mensaje,
                    style: const TextStyle(fontSize: 25.0, color: Colors.red),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
