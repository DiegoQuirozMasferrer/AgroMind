import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled7/DetallesCuartel.dart';
import 'api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestión de Cultivos y Clima',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoading = false;
  Map<String, dynamic>? weatherData;
  final List<Map<String, dynamic>> cuarteles = [];

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    _cargarCuarteles();
  }

  Future<void> _cargarCuarteles() async {
    final prefs = await SharedPreferences.getInstance();
    final cuartelesGuardados = prefs.getStringList('cuarteles') ?? [];
    setState(() {
      cuarteles.clear();
      for (var cuartel in cuartelesGuardados) {
        try {
          final decodedData = json.decode(cuartel) as Map<String, dynamic>;
          cuarteles.add(decodedData);
        } catch (e) {
          print('Error al cargar cuartel: $e');
        }
      }
    });
  }

  Future<void> _guardarCuarteles() async {
    final prefs = await SharedPreferences.getInstance();
    final cuartelesGuardados = cuarteles.map((cuartel) => json.encode(cuartel)).toList();
    await prefs.setStringList('cuarteles', cuartelesGuardados);
  }

  Future<void> _fetchWeatherData() async {
    setState(() => isLoading = true);

    final apiService = ApiService();
    const latitude = -35.4264;
    const longitude = -71.6554;

    try {
      final data = await apiService.fetchWeatherData(
        latitude: latitude,
        longitude: longitude,
      );

      if (data != null) {
        setState(() => weatherData = data);
      }
    } catch (e) {
      print('Error al obtener datos meteorológicos: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _agregarCuartel() async {
    final nombre = await _mostrarDialogoEditarNombre('Nuevo Cuartel');
    if (nombre != null && nombre.isNotEmpty) {
      setState(() {
        cuarteles.add({
          'nombre': nombre,
          'datos': <String, dynamic>{},
        });
      });
      await _guardarCuarteles();
    }
  }

  Future<void> _editarCuartel(int index) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Cuartel'),
        content: Text('¿Estás seguro de que quieres eliminar este cuartel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (respuesta == true) {
      setState(() {
        cuarteles.removeAt(index);
      });
      await _guardarCuarteles();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cuartel eliminado correctamente'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String?> _mostrarDialogoEditarNombre(String titulo, [String? valorInicial]) async {
    final controller = TextEditingController(text: valorInicial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nombre del cuartel',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty) Navigator.pop(context, nombre);
            },
            child: Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Cultivos y Clima',
            style: TextStyle(
                color: colors.onPrimary,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (weatherData != null) _buildWeatherSection(theme, colors),
            const SizedBox(height: 32),
            _buildCuartelesSection(theme, colors),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _agregarCuartel,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        child: Icon(Icons.add_rounded, size: 32),
      ),
    );
  }

  Widget _buildWeatherSection(ThemeData theme, ColorScheme colors) {
    final tempMin = weatherData!['temperature_min']?.toStringAsFixed(1) ?? 'N/A';
    final tempMax = weatherData!['temperature_max']?.toStringAsFixed(1) ?? 'N/A';
    final tempAvg = weatherData!['temperature_avg']?.toStringAsFixed(1) ?? 'N/A';
    final windSpeed = weatherData!['wind_speed_max']?.toStringAsFixed(1) ?? 'N/A';
    final windGust = weatherData!['wind_gust_max']?.toStringAsFixed(1) ?? 'N/A';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(Icons.cloud, color: colors.primary, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('CONDICIONES CLIMÁTICAS',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ],
              ),
            ),
            const Divider(height: 24, thickness: 1),

            _buildWeatherCategory(
              icon: Icons.thermostat,
              title: 'TEMPERATURAS',
              items: [
                _buildWeatherItem(
                  label: 'Mínima',
                  value: '$tempMin°C',
                  iconColor: Colors.blue.shade700,
                ),
                _buildWeatherItem(
                  label: 'Máxima',
                  value: '$tempMax°C',
                  iconColor: Colors.red.shade700,
                ),
                _buildWeatherItem(
                  label: 'Promedio',
                  value: '$tempAvg°C',
                  iconColor: Colors.green.shade700,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildWeatherCategory(
              icon: Icons.air,
              title: 'VIENTO',
              items: [
                _buildWeatherItem(
                  label: 'Velocidad',
                  value: '$windSpeed m/s',
                  iconColor: Colors.blueGrey.shade700,
                ),
                _buildWeatherItem(
                  label: 'Ráfaga',
                  value: '$windGust m/s',
                  iconColor: Colors.blueGrey.shade800,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCategory({
    required IconData icon,
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items,
        ),
      ],
    );
  }

  Widget _buildWeatherItem({
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIconForLabel(label),
              size: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'mínima':
        return Icons.arrow_downward;
      case 'máxima':
        return Icons.arrow_upward;
      case 'promedio':
        return Icons.show_chart;
      case 'velocidad':
        return Icons.air;
      case 'ráfaga':
        return Icons.grain;
      case 'relativa':
        return Icons.water_drop;
      default:
        return Icons.info;
    }
  }

  Widget _buildCuartelesSection(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Cuarteles del Cultivo',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.bold,
              )),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: cuarteles.length,
          itemBuilder: (context, index) => _buildCuartelCard(index, colors),
        ),
      ],
    );
  }

  Widget _buildCuartelCard(int index, ColorScheme colors) {
    final nombre = cuarteles[index]['nombre'];
    final datos = cuarteles[index]['datos'] as Map<String, dynamic>;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _navigateToDetallesCuartel(index),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          constraints: BoxConstraints(
            minHeight: 150,
          ),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.spa, size: 32, color: colors.secondary),
                  const SizedBox(height: 6),

                  // Nombre del cuartel
                  Text(
                    nombre ?? 'Sin nombre',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (datos.isNotEmpty) ...[
                    const SizedBox(height: 6),

                    // Datos del riego - Usamos una columna desplazable
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCompactDataRow('Tiempo',
                              _convertirDecimalAHorasMinutos(datos['riego'] ?? 0.0),),
                            if (datos['tipoRiego'] != null) ...[

                              _buildCompactDataRow(
                                'Tipo',
                                _parseTipoRiego(datos['tipoRiego'].toString()),
                              ),
                              _buildCompactDataRow(
                                'Efic.',
                                '${_getEficienciaRiego(datos['tipoRiego'].toString())}%',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(Icons.delete, size: 18),
                  padding: EdgeInsets.zero, // Elimina padding interno
                  constraints: BoxConstraints(), // Elimina constraints por defecto
                  onPressed: () => _editarCuartel(index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDataRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11, // Fuente más pequeña
              color: Colors.grey[600],
            ),
          ),
          Flexible(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: 11, // Fuente más pequeña
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
  String _convertirDecimalAHorasMinutos(double horasDecimal) {
    if (horasDecimal == null || horasDecimal <= 0) return '0h 00m';

    final horas = horasDecimal.floor();
    final minutos = ((horasDecimal - horas) * 60).round();

    return '${horas}h ${minutos.toString().padLeft(2, '0')}m';
  }
  String _parseTipoRiego(String tipoRiego) {
    switch (tipoRiego.split('.').last) {
      case 'goteo':
        return 'Goteo';
      case 'microaspersion':
        return 'Microaspersión';
      case 'aspersion':
        return 'Aspersión';
      case 'exudacion':
        return 'Exudación';
      case 'cintas':
        return 'Cintas';
      case 'pivoteCentral':
        return 'Pivote Central';
      case 'superficie':
        return 'Superficie';
      case 'manual':
        return 'Manual';
      default:
        return tipoRiego.split('.').last;
    }
  }

  String _getEficienciaRiego(String tipoRiego) {
    final tipo = TipoRiego.values.firstWhere(
          (e) => e.toString() == tipoRiego,
      orElse: () => TipoRiego.manual,
    );

    final eficiencias = {
      TipoRiego.goteo: 90,
      TipoRiego.microaspersion: 85,
      TipoRiego.aspersion: 75,
      TipoRiego.exudacion: 85,
      TipoRiego.cintas: 80,
      TipoRiego.pivoteCentral: 80,
      TipoRiego.superficie: 60,
      TipoRiego.manual: 45,
    };

    return eficiencias[tipo]?.toString() ?? 'N/A';
  }

  Widget _buildCuartelDataRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600])),
          Text(value ?? 'N/A',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800])),
        ],
      ),
    );
  }

  Future<void> _navigateToDetallesCuartel(int index) async {
    final datosActualizados = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetallesCuartel(
          datos: cuarteles[index]['datos'],
          weatherData: weatherData,
          onGuardar: (nuevosDatos) async {
            setState(() => cuarteles[index]['datos'] = nuevosDatos);
            await _guardarCuarteles();
          },
        ),
      ),
    );
  }
}