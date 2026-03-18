import 'package:flutter/material.dart';
import 'package:fcq_app/main.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:fcq_app/funciones.dart';

class Actividad extends StatelessWidget {
  final Map<String, dynamic> item;

  const Actividad({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    Funciones.mantenerSesion(context);
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Funciones.buildAppBar(
              urlFoto: urlFoto,
              clave: clave,
              nombreCompleto: nombreCompleto,
              carrera: carrera)),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(
                '${item['titulo']}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                  'Fecha de inicio: ${Funciones.formatoFecha(item['fecha_ini'])}'),
              if (item['fecha_fin'] != null)
                Text(
                    'Fecha de término: ${Funciones.formatoFecha(item['fecha_fin'])}'),
              if (item['fecha_fin'] == null) const Text(''),
              const SizedBox(height: 20),
              Text(
                '${item['ciclo']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              HtmlWidget(
                // Widget que permite interpretar código HTML
                item['descripcion']
                    .replaceAll(r'\n', '\n')
                    .replaceAll('"', '')
                    .replaceAll('"', '')
                    .replaceAll(r'\', ''),
                //limpia y reemplaza caracteres para que el formato html se muestre correctamente
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
