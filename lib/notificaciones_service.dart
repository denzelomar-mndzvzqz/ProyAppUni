import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'notificacion_model.dart';

class NotificacionesService {
  static const String _key = 'historial_notificaciones';
  static const int _maxNotificaciones = 20;

  // Guardar una nueva notificación
  static Future<void> guardarNotificacion(String titulo, String cuerpo) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<NotificacionLocal> historial = await obtenerHistorial();

    // Crear la nueva notificación
    final nueva = NotificacionLocal(
      titulo: titulo,
      cuerpo: cuerpo,
      fecha: DateTime.now(),
    );

    // Insertar al inicio (la más reciente)
    historial.insert(0, nueva);

    // Limitar a los últimos 20
    if (historial.length > _maxNotificaciones) {
      historial = historial.sublist(0, _maxNotificaciones);
    }

    // Convertir a JSON y guardar
    List<String> jsonList = historial.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, jsonList);
  }

  // Obtener la lista completa
  static Future<List<NotificacionLocal>> obtenerHistorial() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList(_key);

    if (jsonList == null) return [];

    return jsonList.map((e) => NotificacionLocal.fromJson(jsonDecode(e))).toList();
  }

  // Borrar todo el historial (opcional, por si se desea)
  static Future<void> borrarTodo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
