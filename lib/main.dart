import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CalidadAireApp());
}

class CalidadAireApp extends StatelessWidget {
  const CalidadAireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calidad del Aire',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const CalculadoraCalidadAire(),
    );
  }
}

class Ciudad {
  final String nombre;
  final double latitud;
  final double longitud;

  Ciudad({
    required this.nombre,
    required this.latitud,
    required this.longitud,
  });
}

class CalculadoraCalidadAire extends StatefulWidget {
  const CalculadoraCalidadAire({super.key});

  @override
  State<CalculadoraCalidadAire> createState() =>
      _CalculadoraCalidadAireState();
}

class _CalculadoraCalidadAireState extends State<CalculadoraCalidadAire> {
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController horasController = TextEditingController();

  final List<Ciudad> ciudades = [
    Ciudad(nombre: 'Medellín', latitud: 6.2442, longitud: -75.5812),
    Ciudad(nombre: 'Bogotá', latitud: 4.7110, longitud: -74.0721),
    Ciudad(nombre: 'Cali', latitud: 3.4516, longitud: -76.5320),
    Ciudad(nombre: 'Cartagena', latitud: 10.3910, longitud: -75.4794),
    Ciudad(nombre: 'Barranquilla', latitud: 10.9685, longitud: -74.7813),
  ];

  Ciudad? ciudadSeleccionada;

  double? promedioPM25;
  double? indiceExposicion;
  String? nivelRiesgo;
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    ciudadSeleccionada = ciudades[0];
    fechaController.text = '2025-10-07';
  }

  Future<void> calcularIndice() async {
    if (ciudadSeleccionada == null ||
        fechaController.text.isEmpty ||
        horasController.text.isEmpty) {
      mostrarMensaje('Por favor completa todos los campos');
      return;
    }

    double? horasExposicion = double.tryParse(horasController.text);

    if (horasExposicion == null || horasExposicion <= 0) {
      mostrarMensaje('Ingresa un número válido de horas');
      return;
    }

    setState(() {
      cargando = true;
      promedioPM25 = null;
      indiceExposicion = null;
      nivelRiesgo = null;
    });

    try {
      final ciudad = ciudadSeleccionada!;
      final fecha = fechaController.text;

      final url = Uri.parse(
        'https://air-quality-api.open-meteo.com/v1/air-quality'
        '?latitude=${ciudad.latitud}'
        '&longitude=${ciudad.longitud}'
        '&hourly=pm2_5'
        '&start_date=$fecha'
        '&end_date=$fecha',
      );

      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);

        final List valoresPM25 = datos['hourly']['pm2_5'];

        double suma = 0;
        int cantidadDatosValidos = 0;

        for (var valor in valoresPM25) {
          if (valor != null) {
            suma += valor;
            cantidadDatosValidos++;
          }
        }

        if (cantidadDatosValidos == 0) {
          mostrarMensaje('No hay datos disponibles para esa fecha');
          return;
        }

        double promedio = suma / cantidadDatosValidos;
        double indice = promedio * horasExposicion;
        String riesgo = clasificarRiesgo(indice);

        setState(() {
          promedioPM25 = promedio;
          indiceExposicion = indice;
          nivelRiesgo = riesgo;
        });
      } else {
        mostrarMensaje('Error al consultar la API');
      }
    } catch (e) {
      mostrarMensaje('Ocurrió un error al obtener los datos');
    } finally {
      setState(() {
        cargando = false;
      });
    }
  }

  String clasificarRiesgo(double indice) {
    if (indice < 100) {
      return 'Bajo';
    } else if (indice >= 100 && indice <= 200) {
      return 'Moderado';
    } else {
      return 'Alto';
    }
  }

  void mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> seleccionarFecha() async {
    DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime(2025, 10, 7),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (fecha != null) {
      String fechaFormateada =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

      setState(() {
        fechaController.text = fechaFormateada;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Calidad del Aire'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Ciudad>(
                value: ciudadSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Ciudad',
                  border: OutlineInputBorder(),
                ),
                items: ciudades.map((ciudad) {
                  return DropdownMenuItem(
                    value: ciudad,
                    child: Text(ciudad.nombre),
                  );
                }).toList(),
                onChanged: (Ciudad? nuevaCiudad) {
                  setState(() {
                    ciudadSeleccionada = nuevaCiudad;
                  });
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: fechaController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Fecha de consulta',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                onTap: seleccionarFecha,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: horasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Horas de exposición diaria',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: cargando ? null : calcularIndice,
                child: cargando
                    ? const CircularProgressIndicator()
                    : const Text('Calcular Nivel de Riesgo'),
              ),

              const SizedBox(height: 30),

              if (indiceExposicion != null && nivelRiesgo != null)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Promedio PM2.5: ${promedioPM25!.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Índice de exposición: ${indiceExposicion!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nivel de riesgo: $nivelRiesgo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: obtenerColorRiesgo(nivelRiesgo!),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color obtenerColorRiesgo(String riesgo) {
    if (riesgo == 'Bajo') {
      return Colors.green;
    } else if (riesgo == 'Moderado') {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}