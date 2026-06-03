import 'package:fcq_app/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseApi {
  // Instancia de firebase messaging
  final firebase = FirebaseMessaging.instance;

  // Canal de notificación para Android (necesario para prioridad alta)
  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'Notificaciones Importantes', // nombre
    description: 'Este canal se usa para notificaciones críticas.',
    importance: Importance.max,
  );

  // Instancia de notificaciones locales
  final _localNotifications = FlutterLocalNotificationsPlugin();

  // Función para inicializar notificaciones
  Future<void> iniNotificacion() async {
    try {
      // Esperar un momento para asegurar que los servicios de Google estén listos
      await Future.delayed(const Duration(seconds: 1));

      // Pedir permiso al usuario
      await firebase.requestPermission();

      // Obtener el token del dispositivo actual
      final token = await firebase.getToken();

      if (token != null) {
        SharedPreferences pref = await SharedPreferences.getInstance();
        await pref.setString('dispositivo_token', token);
        print('🔥 FIREBASE TOKEN: $token');
        
        // RE-SUSCRIBIR SOLO SI HAY SESIÓN ACTIVA
        final String? clave = pref.getString('clave_unica');
        if (clave != null && clave.isNotEmpty) {
          await firebase.subscribeToTopic('Actividades');
          print('✅ Suscrito al tema Actividades');
        }
      }

      // Inicializar notificaciones locales
      await _initLocalNotifications();
      
      // Configurar los listeners de mensajes
      iniPushNotificacion();
    } catch (e) {
      print('⚠️ Firebase no se pudo inicializar completamente: $e');
    }
  }

  // Inicialización de notificaciones locales (para mostrar banners en primer plano)
  Future _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // Lógica cuando el usuario toca la notificación local
        final message = RemoteMessage.fromMap({'data': response.payload});
        manejarMensaje(message);
      },
    );

    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  // Funcion que manda al usuario a una pantalla específica cuando da clic en la notificación
  void manejarMensaje(RemoteMessage? mensaje) {
    if (mensaje == null) return;

    navigatorKey.currentState?.pushNamed(
      '/index',
    );
  }

  // Funcion que inicializa los ajustes cuando la app está terminada
  Future iniPushNotificacion() async {
    // Manejar notificación cuando la app se abre desde un estado terminado
    FirebaseMessaging.instance.getInitialMessage().then(manejarMensaje);

    // Detector de eventos cuando la notificación abre la app (segundo plano)
    FirebaseMessaging.onMessageOpenedApp.listen(manejarMensaje);

    // Manejar notificaciones en primer plano (MOSTRAR BANNER)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notification = message.notification;
      if (notification == null) return;

      // VERIFICACIÓN DE SEGURIDAD: Solo mostrar si el usuario está logueado
      SharedPreferences pref = await SharedPreferences.getInstance();
      final String? clave = pref.getString('clave_unica');
      
      if (clave == null || clave.isEmpty) {
        print('🚫 Notificación ignorada: No hay sesión activa.');
        return;
      }

      print('🔔 Mensaje recibido en PRIMER PLANO: ${notification.title}');

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: message.data.toString(),
      );
    });
  }
}
