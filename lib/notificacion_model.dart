
class NotificacionLocal {
  final String titulo;
  final String cuerpo;
  final DateTime fecha;

  NotificacionLocal({
    required this.titulo,
    required this.cuerpo,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'cuerpo': cuerpo,
        'fecha': fecha.toIso8601String(),
      };

  factory NotificacionLocal.fromJson(Map<String, dynamic> json) => NotificacionLocal(
        titulo: json['titulo'] ?? '',
        cuerpo: json['cuerpo'] ?? '',
        fecha: DateTime.parse(json['fecha'] ?? DateTime.now().toIso8601String()),
      );
}
