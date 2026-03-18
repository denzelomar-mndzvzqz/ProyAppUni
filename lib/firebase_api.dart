import 'package:fcq_app/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  //instancia de firebase messaging
  final firebase = FirebaseMessaging.instance;

  //Función para inicializar notificaciones
  Future<void> iniNotificacion() async {
    //Pedir permiso al usuario
    await firebase.requestPermission();

    //Suscribe automáticamente al usuario al tema de Actividades
    await firebase.subscribeToTopic('Actividades');

    //Obtener el token del dispositivo actual
    final token = await firebase.getToken();

    //Mandar token al servidor en caso de querer identificar cada dispositivo
    // ignore: avoid_print
    print('token: $token');

    iniPushNotificacion();
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
