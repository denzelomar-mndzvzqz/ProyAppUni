import 'package:fcq_app/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseApi {
  //instancia de firebase messaging
  final firebase = FirebaseMessaging.instance;

  //Función para inicializar notificaciones
  Future<void> iniNotificacion() async {
    try {
      //Pedir permiso al usuario (con timeout para no bloquear)
      await firebase.requestPermission().timeout(const Duration(seconds: 5));

      //Suscribe automáticamente al usuario al tema de Actividades
      await firebase.subscribeToTopic('Actividades').timeout(const Duration(seconds: 5));

      //Obtener el token del dispositivo actual
      final token = await firebase.getToken();

      if (token != null) {
        SharedPreferences pref = await SharedPreferences.getInstance();
        await pref.setString('dispositivo_token', token);
        print('✅ Firebase Token obtenido exitosamente');
      }

      iniPushNotificacion();
    } catch (e) {
      print('⚠️ Firebase no se pudo inicializar completamente: $e');
      // No lanzamos error para no romper el flujo de la App
    }
  }

  //Funcion que manda al usuario a una pantalla específica cuando da clic en la notificación
  void manejarMensaje(RemoteMessage? mensaje) {
    if (mensaje == null) return;

    navigatorKey.currentState?.pushNamed(
      '/index',
    );
  }

  //Funcion que inicializa los ajustes cuando la app está terminada
  Future iniPushNotificacion() async {
    //manejar notificación
    FirebaseMessaging.instance.getInitialMessage().then(manejarMensaje);

    //detector de eventos cuando la notificación abre la app
    FirebaseMessaging.onMessageOpenedApp.listen(manejarMensaje);
  }
}
