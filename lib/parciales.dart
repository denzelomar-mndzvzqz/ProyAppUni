// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:fcq_app/main.dart';
import 'package:fcq_app/funciones.dart';

class Parciales extends StatefulWidget {
  const Parciales({super.key});

  @override
  _Parcial createState() => _Parcial();
}

class _Parcial extends State<Parciales> {
  String mensaje = '';
  List<dynamic> parciales = [];
  bool isLoading = false;

  //Función que asegura que la lista de materias (parciales) se actualice para mostrar correctamente
  void actualizaParciales(List<dynamic> parcial, bool L) {
    setState(() {
      parciales = parcial;
      isLoading = L;
    });
  }

  //Función que actualiza el mensaje en caso de que la clave o contraseña sean incorrectos
  void actualizaMensaje(String nuevoMensaje) {
    setState(() {
      mensaje = nuevoMensaje;
    });
  }

  @override
  void initState() {
    super.initState();
    isLoading = true;
    Funciones.obtenerParciales(
        parciales, isLoading, setState, actualizaParciales, actualizaMensaje);
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
      body: Column(children: [
        Visibility(
            visible: mensaje.isNotEmpty,
            child: Text(
              // Mensaje de error en caso de no encontrar actividades
              mensaje,
              style: const TextStyle(fontSize: 25.0, color: Colors.red),
            )),
        Expanded(
            child: SizedBox(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: parciales.length,
                  itemBuilder: (context, index) {
                    final parcial = parciales[index];
                    return SizedBox(
                      height: 170,
                      child: Card(
                        color: const Color.fromARGB(255, 220, 220, 220),
                        child: Column(
                          children: [
                            ListTile(
                              //Aquí se extrae el contenido de la función Future<String> obtenerMateria()
                              title: parcial['nombre_mat'],
                              subtitle: Padding(
                                padding: const EdgeInsets.only(
                                    bottom:
                                        16.0), // Espaciado solo en la parte inferior
                                child: Text(
                                    'Profesor: ${parcial['nombre_pro'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    )),
                              ),
                            ),
                            Table(
                              border: TableBorder.symmetric(
                                inside: const BorderSide(
                                    width: 1.0,
                                    color: Color.fromARGB(255, 150, 150,
                                        150)), // Borde entre celdas
                                outside: BorderSide
                                    .none, // No se muestra el borde exterior
                              ),
                              children: [
                                TableRow(
                                  children: [
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: const Center(
                                          child: Text(
                                            'P1',
                                            style: TextStyle(
                                                fontWeight: FontWeight
                                                    .bold), // Aplica negritas
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: const Center(
                                          child: Text(
                                            'P2',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: const Center(
                                          child: Text(
                                            'P3',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: const Center(
                                          child: Text(
                                            'P4',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: const Center(
                                          child: Text(
                                            'P5',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: const Center(
                                          child: Text(
                                            'EO',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: const Center(
                                          child: Text(
                                            'EE',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: const Center(
                                          child: Text(
                                            'ET',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                TableRow(
                                  children: [
                                    // Los signos ?? (operador de fusión nula) proporcionan un valor de respaldo en caso de que el campo sea null
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Center(
                                          child:
                                              Text(parcial['parcial_1'] ?? ''),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Center(
                                          child:
                                              Text(parcial['parcial_2'] ?? ''),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Center(
                                          child:
                                              Text(parcial['parcial_3'] ?? ''),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Center(
                                          child:
                                              Text(parcial['parcial_4'] ?? ''),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Center(
                                          child:
                                              Text(parcial['parcial_5'] ?? ''),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Center(
                                          child:
                                              Text(parcial['final_ord'] ?? ''),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Center(
                                          child:
                                              Text(parcial['final_ee'] ?? ''),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Center(
                                          child:
                                              Text(parcial['final_et'] ?? ''),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        )),
      ]),
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
