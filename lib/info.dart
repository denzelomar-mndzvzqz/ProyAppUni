// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:fcq_app/main.dart';
import 'package:fcq_app/funciones.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  _Informacion createState() => _Informacion();
}

class _Informacion extends State<Info> {
  WebViewController webControlador = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.disabled)
    ..loadRequest(Uri.parse(
        'https://flutter.dev/?gclid=CjwKCAiAxreqBhAxEiwAfGfndLDd8ZpaLD8Lw6Oxs0qJ2Jbud83aTn6G7V4Gp_yPhYChY7KMmwkGlRoCLOoQAvD_BwE&gclsrc=aw.ds'));

  @override
  void initState() {
    super.initState();
    Funciones.mantenerSesion(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Funciones.buildAppBar(
              urlFoto: urlFoto,
              clave: clave,
              nombreCompleto: nombreCompleto,
              carrera: carrera)),
      body: WebViewWidget(controller: webControlador),
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