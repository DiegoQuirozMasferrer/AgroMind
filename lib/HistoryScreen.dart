import 'package:flutter/material.dart';
import 'api_service.dart';

class HistoricoRiego extends StatefulWidget {
  final String nombreCuartel;
  final double latitud;
  final double longitud;

  const HistoricoRiego({
    Key? key,
    required this.nombreCuartel,
    required this.latitud,
    required this.longitud,
  }) : super(key: key);

  @override
  _HistoricoRiegoState createState() => _HistoricoRiegoState();
}

class _HistoricoRiegoState extends State<HistoricoRiego> {
  late Future<Map<String, dynamic>> _historicoData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHistorico();
  }

  Future<void> _cargarHistorico() async {
    setState(() => _isLoading = true);
    try {
      final apiService = ApiService();
      _historicoData = apiService.obtenerHistoricoMeteorologico(
        widget.latitud,
        widget.longitud,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico - ${widget.nombreCuartel}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FutureBuilder<Map<String, dynamic>>(
        future: _historicoData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No hay datos históricos'));
          }

          return _buildHistoricoList(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildHistoricoList(Map<String, dynamic> datos) {
    final dailyData = datos['daily'];
    final timeList = dailyData['time'] as List<dynamic>;
    final et0List = dailyData['et0_fao_evapotranspiration'] as List<dynamic>;
    final tempMaxList = dailyData['temperature_2m_max'] as List<dynamic>;
    final tempMinList = dailyData['temperature_2m_min'] as List<dynamic>;
    final windMaxList = dailyData['wind_speed_10m_max'] as List<dynamic>;

    // Filtrar solo fechas pasadas
    final now = DateTime.now();
    final historicalDates = <String>[];
    final historicalIndices = <int>[];

    for (int i = 0; i < timeList.length; i++) {
      final date = DateTime.parse(timeList[i]);
      if (date.isBefore(now)) {
        historicalDates.add(timeList[i]);
        historicalIndices.add(i);
      }
    }

    // Ordenar de más reciente a más antiguo
    historicalDates.sort((a, b) => b.compareTo(a));
    historicalIndices.sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: historicalDates.length,
      itemBuilder: (context, index) {
        final dataIndex = historicalIndices[index];

        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatearFecha(timeList[dataIndex]),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                _buildDatoHistorico('ET0', '${et0List[dataIndex]?.toStringAsFixed(2) ?? 'N/A'} mm'),
                _buildDatoHistorico('Temp. Máx', '${tempMaxList[dataIndex]?.toStringAsFixed(1) ?? 'N/A'}°C'),
                _buildDatoHistorico('Temp. Mín', '${tempMinList[dataIndex]?.toStringAsFixed(1) ?? 'N/A'}°C'),
                _buildDatoHistorico('Viento Máx', '${windMaxList[dataIndex]?.toStringAsFixed(1) ?? 'N/A'} km/h'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDatoHistorico(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final date = DateTime.parse(fecha);
      return '${_getDiaSemana(date.weekday)} ${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  String _getDiaSemana(int weekday) {
    const dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return dias[weekday % 7];
  }
}