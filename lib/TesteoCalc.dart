import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class TesteoCalc extends StatefulWidget {
  @override
  _TesteoCalcState createState() => _TesteoCalcState();
}

class _TesteoCalcState extends State<TesteoCalc> {
  // Controladores para los campos de entrada
  final _tempMaxController = TextEditingController();
  final _tempMinController = TextEditingController();
  final _kcController = TextEditingController(text: '1.0');
  final _latController = TextEditingController(text: '-35.4264');

  // Resultados
  double _etoCalculada = 0;
  double _etcCalculada = 0;
  double? _referenciaEto;
  double _errorPorcentual = 0;
  bool _mostrarDetalles = false;

  @override
  void dispose() {
    _tempMaxController.dispose();
    _tempMinController.dispose();
    _kcController.dispose();
    _latController.dispose();
    super.dispose();
  }

  // Función para calcular ET0 (simplificada para pruebas)
  void _calcularET0() {
    final tMax = double.tryParse(_tempMaxController.text) ?? 0;
    final tMin = double.tryParse(_tempMinController.text) ?? 0;
    final lat = double.tryParse(_latController.text) ?? -35.4264;
    final kc = double.tryParse(_kcController.text) ?? 1.0;

    // Fórmula simplificada para prueba (basada en Hargreaves)
    final tAvg = (tMax + tMin) / 2;
    final rs = 15 + 0.5 * tAvg; // Simulación de radiación solar

    setState(() {
      _etoCalculada = 0.0023 * (tAvg + 17.8) * sqrt(tMax - tMin) * rs;
      _etcCalculada = _etoCalculada * kc;

      if (_referenciaEto != null) {
        _errorPorcentual = ((_etoCalculada - _referenciaEto!).abs() / _referenciaEto!) * 100;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Validación de Cálculos'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () => setState(() => _mostrarDetalles = !_mostrarDetalles),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputCard(),
            SizedBox(height: 20),
            _buildResultsCard(),
            if (_mostrarDetalles) _buildTechnicalDetailsCard(),
            SizedBox(height: 20),
            _buildTestCasesTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Datos de Entrada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            _buildNumberInput(_tempMaxController, 'Temperatura Máxima (°C)', Icons.thermostat),
            _buildNumberInput(_tempMinController, 'Temperatura Mínima (°C)', Icons.thermostat),
            _buildNumberInput(_latController, 'Latitud', Icons.location_on),
            _buildNumberInput(_kcController, 'Coeficiente Cultivo (Kc)', Icons.grass),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.calculate),
                    label: Text('Calcular'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: _calcularET0,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.compare),
                    label: Text('Comparar'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => _buildReferenceDialog(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberInput(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
          filled: true,
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[\-]?\d*\.?\d{0,2}'))],
      ),
    );
  }

  Widget _buildResultsCard() {
    return Card(
      elevation: 4,
      color: _errorPorcentual > 5 ? Colors.orange[50] : Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Resultados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_referenciaEto != null)
                  Chip(
                    label: Text('Error: ${_errorPorcentual.toStringAsFixed(2)}%'),
                    backgroundColor: _errorPorcentual > 5 ? Colors.orange : Colors.green,
                  ),
              ],
            ),
            SizedBox(height: 16),
            Table(
              columnWidths: {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
              children: [
                _buildTableRow('ET₀ calculada', '${_etoCalculada.toStringAsFixed(2)} mm/día'),
                if (_referenciaEto != null)
                  _buildTableRow('ET₀ referencia', '${_referenciaEto!.toStringAsFixed(2)} mm/día'),
                _buildTableRow('ETc (Kc=${_kcController.text})', '${_etcCalculada.toStringAsFixed(2)} mm/día'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(value),
        ),
      ],
    );
  }

  Widget _buildTechnicalDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalles Técnicos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Fórmula usada: ET₀ = 0.0023 * (Tavg + 17.8) * √(Tmax - Tmin) * Rs'),
            SizedBox(height: 8),
            Text('Donde:'),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('- Tavg = (Tmax + Tmin)/2'),
                  Text('- Rs = Radiación solar estimada (MJ/m²/día)'),
                  Text('- ETc = ET₀ * Kc'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestCasesTable() {
    final testCases = [
      {'tmax': 28.5, 'tmin': 14.3, 'lat': -35.4, 'ref': 3.8, 'desc': 'Verano típico'},
      {'tmax': 18.2, 'tmin': 7.6, 'lat': -35.4, 'ref': 2.1, 'desc': 'Otoño fresco'},
      {'tmax': 12.0, 'tmin': 3.5, 'lat': -35.4, 'ref': 1.4, 'desc': 'Invierno frío'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Casos de Prueba', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Table(
              border: TableBorder.all(),
              columnWidths: {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  children: [
                    _buildTableCell('Escenario', isHeader: true),
                    _buildTableCell('Tmax', isHeader: true),
                    _buildTableCell('Tmin', isHeader: true),
                    _buildTableCell('Ref', isHeader: true),
                    _buildTableCell('Acción', isHeader: true),
                  ],
                ),
                ...testCases.map((testCase) => TableRow(
                  children: [
                    _buildTableCell(testCase['desc'].toString()),
                    _buildTableCell(testCase['tmax'].toString()),
                    _buildTableCell(testCase['tmin'].toString()),
                    _buildTableCell(testCase['ref'].toString()),
                    _buildTableCell(
                      '',
                      action: IconButton(
                        icon: Icon(Icons.play_arrow, size: 20),
                        onPressed: () {
                          setState(() {
                            _tempMaxController.text = testCase['tmax'].toString();
                            _tempMinController.text = testCase['tmin'].toString();
                            _latController.text = testCase['lat'].toString();
                            _referenciaEto = (testCase['ref'] as num).toDouble();
                            _calcularET0();
                          });
                        },
                      ),
                    ),
                  ],
                )).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Widget? action}) {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Center(
        child: action ?? Text(
          text,
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceDialog() {
    final refController = TextEditingController();
    return AlertDialog(
      title: Text('Ingresar Valor de Referencia'),
      content: TextField(
        controller: refController,
        decoration: InputDecoration(
          labelText: 'ET₀ referencia (mm/día)',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _referenciaEto = double.tryParse(refController.text);
              if (_referenciaEto != null) {
                _errorPorcentual = ((_etoCalculada - _referenciaEto!).abs() / _referenciaEto!) * 100;
              }
            });
            Navigator.pop(context);
          },
          child: Text('Aceptar'),
        ),
      ],
    );
  }
}