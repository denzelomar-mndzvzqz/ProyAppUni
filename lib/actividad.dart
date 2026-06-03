import 'package:flutter/material.dart';
import 'package:fcq_app/main.dart' as globals;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:fcq_app/funciones.dart';
import 'package:url_launcher/url_launcher.dart';

class Actividad extends StatelessWidget {
  final Map<String, dynamic> item;

  const Actividad({super.key, required this.item});

  // Función para abrir enlaces externos (Inscripción o Archivos)
  Future<void> _lanzarURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir la URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ya no llamamos a mantenerSesion aquí para evitar saltos de pantalla
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Funciones.buildAppBar(
              urlFoto: globals.urlFoto,
              clave: globals.clave,
              nombreCompleto: globals.nombreCompleto,
              carrera: globals.carrera)),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCabeceraInformativa(),
              const SizedBox(height: 25),
              HtmlWidget(
                item['descripcion'] ?? "",
                textStyle: const TextStyle(fontSize: 16),
                onTapUrl: (url) async {
                  await _lanzarURL(url);
                  return true;
                },
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 8, 50, 96)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 8),
                // Botón de Inscripción (si existe link)
                if (item['link'] != null && item['link'].toString().isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: () => _lanzarURL(item['link']),
                    icon: const Icon(Icons.edit_note),
                    label: const Text("Inscribirse"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                ],
                // Botón de Archivo Adjunto (si existe)
                if (item['archivo'] != null && item['archivo'].toString().isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () =>
                        _lanzarURL("https://fcq.uaslp.mx/secciones/api/archivos/${item['archivo']}"),
                    icon: const Icon(Icons.file_present),
                    label: const Text("Ver PDF"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCabeceraInformativa() {
    final fechaInicio = DateTime.parse(item['fecha_ini']);
    final fechaFin = item['fecha_fin'] != null ? DateTime.parse(item['fecha_fin']) : null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);

    Color color;
    String statusTexto;
    bool esVigente = false;

    if (fechaFin != null) {
      esVigente = now.isAfter(fechaInicio) && now.isBefore(fechaFin);
    } else {
      esVigente = today.isAtSameMomentAs(startDay);
    }

    if (esVigente) {
      color = Colors.green;
      statusTexto = "VIGENTE";
    } else if (now.isBefore(fechaInicio)) {
      color = Colors.blueAccent;
      statusTexto = "PRÓXIMAMENTE";
    } else {
      // Si no tiene fecha de fin y ya pasó, usamos un color más neutro (Gris)
      color = item['fecha_fin'] == null ? Colors.blueGrey : Colors.redAccent;
      statusTexto = "FINALIZADA";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  '${item['titulo']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 8, 50, 96),
                  ),
                ),
              ),
              if (item['requisito'] == '1')
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 2.0),
                  child: Icon(Icons.warning, color: Colors.red, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 15),
          // Fila de Inicio
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: color),
              const SizedBox(width: 10),
              Text(
                'Inicio: ${Funciones.formatoFecha(item['fecha_ini'])}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              // Solo PRÓXIMAMENTE se queda en la fila de Inicio
              if (statusTexto == "PRÓXIMAMENTE") ...[
                const Spacer(),
                _buildBadge(statusTexto, color),
              ]
            ],
          ),
          // Fila de Término: Solo se muestra si hay una fecha de fin distinta o si está VIGENTE/FINALIZADA con fin
          if (item['fecha_fin'] != null || statusTexto == "VIGENTE") ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.event_available, size: 16, color: color),
                const SizedBox(width: 10),
                Text(
                  'Término: ${Funciones.formatoFecha(item['fecha_fin'] ?? item['fecha_ini'])}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                // VIGENTE siempre se muestra. FINALIZADA solo si tenía fecha de fin.
                if (statusTexto == "VIGENTE" || (statusTexto == "FINALIZADA" && item['fecha_fin'] != null)) ...[
                  const Spacer(),
                  _buildBadge(statusTexto, color),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }
}
