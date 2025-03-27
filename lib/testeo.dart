import 'package:flutter/material.dart';

class SimplifiedScreen extends StatefulWidget {
  @override
  _SimplifiedScreenState createState() => _SimplifiedScreenState();
}

class _SimplifiedScreenState extends State<SimplifiedScreen> {
  final double eto = 7.0; // ETo fijo en mm/día
  final double kc = 0.75; // Kc fijo
  final String species = 'Palto'; // Especie fija
  final String irrigationType = 'Goteo'; // Tipo de riego fijo

  final TextEditingController plantingFrameController =
  TextEditingController(text: '6.0'); // Marco de plantación por defecto
  final TextEditingController flowRateController =
  TextEditingController(); // Entrada del caudal

  double? etc; // Valor calculado de ETc
  double? waterNeed; // Necesidad hídrica
  double? netDemandInM3; // Demanda neta ajustada en m³/ha
  double? irrigationTime; // Tiempo de riego en horas

  @override
  void initState() {
    super.initState();
    _calculateValues();
  }

  void _calculateValues() {
    setState(() {
      // Calcula ETc
      etc = eto * kc;
      print('ETc Calculado: ${etc?.toStringAsFixed(2)} mm/día');

      // Calcula necesidad hídrica
       // Sin ajuste por humedad, necesidad hídrica = ETc


      // Calcula demanda neta ajustada
      final plantingFrame = double.tryParse(plantingFrameController.text) ?? 0.0;
      final plantsPerHa = plantingFrame > 0 ? (10000 / plantingFrame) : 0.0;
      final irrigationEfficiency = 0.90; // Eficiencia para goteo
      waterNeed = (etc!/irrigationEfficiency);
      print('Necesidad Hídrica: ${waterNeed?.toStringAsFixed(2)} mm/día');
      final netDemandInMm = (waterNeed! *  plantingFrame);

      netDemandInM3 = netDemandInMm*0.01 ; // Conversión mm/ha a m³/ha
      print('irrigacion: ${irrigationEfficiency?.toStringAsFixed(2)} ');
      print('Demanda Neta Ajustada: ${netDemandInM3?.toStringAsFixed(2)} m³/ha');

      // Calcula tiempo de riego
      final flowRate = double.tryParse(flowRateController.text) ?? 0.0;
      if (netDemandInM3 != null && flowRate > 0) {
        irrigationTime = netDemandInM3! / flowRate; // Tiempo en horas
        print('Tiempo de Riego Calculado: ${irrigationTime?.toStringAsFixed(2)} horas');
      } else {
        irrigationTime = null;
        print('No se puede calcular el Tiempo de Riego: caudal inválido.');
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simplified Irrigation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Especie: $species',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Tipo de riego: $irrigationType',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            TextField(
              controller: plantingFrameController,
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateValues(),
              decoration: InputDecoration(
                labelText: 'Marco de Plantación (m² por planta)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: flowRateController,
              keyboardType: TextInputType.number,
              onChanged: (value) => _calculateValues(),
              decoration: InputDecoration(
                labelText: 'Caudal (m³/hora)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            SensorCard(
              title: 'ETc Calculado',
              icon: Icons.water_drop,
              value: '${etc?.toStringAsFixed(2) ?? "Sin datos"} mm/día',
              color: Colors.blueAccent,
            ),
            SensorCard(
              title: 'Necesidad Hídrica',
              icon: Icons.water,
              value: '${waterNeed?.toStringAsFixed(2) ?? "Sin datos"} mm/día',
              color: Colors.lightBlue,
            ),
            SensorCard(
              title: 'Demanda Neta Ajustada',
              icon: Icons.calculate,
              value: '${netDemandInM3?.toStringAsFixed(2) ?? "Sin datos"} m³/ha',
              color: Colors.green,
            ),
            SensorCard(
              title: 'Tiempo de Riego',
              icon: Icons.timer,
              value: '${irrigationTime?.toStringAsFixed(2) ?? "Sin datos"} horas',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

class SensorCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String value;
  final Color color;

  SensorCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
