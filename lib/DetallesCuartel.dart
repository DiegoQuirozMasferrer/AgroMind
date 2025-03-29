import 'dart:math';
import 'package:flutter/material.dart';
import 'HistoryScreen.dart';

enum TipoRiego {
  goteo(tecnificado: true, nombre: 'Riego por Goteo'),
  microaspersion(tecnificado: true, nombre: 'Microaspersión'),
  aspersion(tecnificado: true, nombre: 'Aspersión'),
  exudacion(tecnificado: true, nombre: 'Riego por Exudación'),
  cintas(tecnificado: true, nombre: 'Cintas de Riego'),
  pivoteCentral(tecnificado: true, nombre: 'Pivote Central'),
  superficie(tecnificado: false, nombre: 'Riego por Superficie'),
  manual(tecnificado: false, nombre: 'Riego Manual');

  final bool tecnificado;
  final String nombre;
  const TipoRiego({required this.tecnificado, required this.nombre});
}

class DetallesCuartel extends StatefulWidget {
  final Map<String, dynamic> datos;
  final Map<String, dynamic>? weatherData;
  final Function(Map<String, dynamic>) onGuardar;

  const DetallesCuartel({
    Key? key,
    required this.datos,
    this.weatherData,
    required this.onGuardar,
  }) : super(key: key);

  @override
  _DetallesCuartelState createState() => _DetallesCuartelState();
}

class _DetallesCuartelState extends State<DetallesCuartel> {
  final _formKey = GlobalKey<FormState>();
  final _controllerKc = TextEditingController();
  final _controllerCaudal = TextEditingController();
  final _controllerEmisores = TextEditingController();
  final _controllerSobre = TextEditingController();
  final _controllerEntre = TextEditingController();
  double? _etc;
  double? _tiempoRiego;
  double? _etoHargreaves;
  TipoRiego _tipoRiego = TipoRiego.goteo;

  final Map<TipoRiego, double> _eficienciaRiego = {
    TipoRiego.goteo: 0.90,
    TipoRiego.microaspersion: 0.85,
    TipoRiego.aspersion: 0.75,
    TipoRiego.exudacion: 0.85,
    TipoRiego.cintas: 0.80,
    TipoRiego.pivoteCentral: 0.80,
    TipoRiego.superficie: 0.60,
    TipoRiego.manual: 0.45,
  };

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeTipoRiego();
    _calculateInitialValues();
  }

  void _initializeControllers() {
    _controllerKc.text = widget.datos['kc']?.toString() ?? '';
    _controllerCaudal.text = widget.datos['caudal']?.toString() ?? '';
    _controllerEmisores.text = widget.datos['emisores']?.toString() ?? '';
    _controllerSobre.text = widget.datos['Sobre']?.toString() ?? '';
    _controllerEntre.text = widget.datos['Entre']?.toString() ?? '';

    // Add listeners for automatic saving
    _controllerKc.addListener(_guardarAutomaticamente);
    _controllerCaudal.addListener(_guardarAutomaticamente);
    _controllerEmisores.addListener(_guardarAutomaticamente);
    _controllerSobre.addListener(_guardarAutomaticamente);
    _controllerEntre.addListener(_guardarAutomaticamente);
  }

  void _initializeTipoRiego() {
    if (widget.datos['tipoRiego'] != null) {
      _tipoRiego = TipoRiego.values.firstWhere(
            (e) => e.toString() == widget.datos['tipoRiego'],
        orElse: () => TipoRiego.goteo,
      );
    }
  }

  void _calculateInitialValues() {
    if (widget.weatherData != null) {
      _etoHargreaves = _calcularEToHargreaves(widget.weatherData!);
      _recalcularETo();
    }
  }

  @override
  void dispose() {
    // Remove listeners when widget is disposed
    _controllerKc.removeListener(_guardarAutomaticamente);
    _controllerCaudal.removeListener(_guardarAutomaticamente);
    _controllerEmisores.removeListener(_guardarAutomaticamente);
    _controllerSobre.removeListener(_guardarAutomaticamente);
    _controllerEntre.removeListener(_guardarAutomaticamente);

    _controllerKc.dispose();
    _controllerCaudal.dispose();
    _controllerEmisores.dispose();
    _controllerSobre.dispose();
    _controllerEntre.dispose();
    super.dispose();
  }

  void _guardarAutomaticamente() {
    if (_formKey.currentState?.validate() ?? false) {
      final nuevosDatos = {
        'kc': _controllerKc.text,
        'caudal': _controllerCaudal.text,
        'emisores': _controllerEmisores.text,
        'Area1': _controllerSobre.text,
        'Area2': _controllerEntre.text,
        'riego': _tiempoRiego,
        'tipoRiego': _tipoRiego.toString(),
      };
      widget.onGuardar(nuevosDatos);
    }
  }

  void _recalcularETo() {
    if (widget.weatherData == null) return;

    setState(() {
      _etoHargreaves = widget.weatherData?['et0_fao_evapotranspiration'];
      //_etoHargreaves = _calcularEToHargreaves(widget.weatherData!);
      final kc = double.tryParse(_controllerKc.text) ?? 0.0;
      _etc = (_etoHargreaves ?? 0.0) * kc;
      _calcularTiempoRiego();
      _guardarAutomaticamente();
    });
  }

  void _calcularTiempoRiego() {
    final area1 = double.tryParse(_controllerSobre.text) ?? 1.0;
    final area2 = double.tryParse(_controllerEntre.text) ?? 1.0;
    final caudal = double.tryParse(_controllerCaudal.text) ?? 0.0;
    final emisores = int.tryParse(_controllerEmisores.text) ?? 0;
    final eficiencia = _eficienciaRiego[_tipoRiego] ?? 0.9;

    if (caudal > 0 && emisores > 0 && _etc != null) {
      final volumenAgua = _etc! * (area1*area2);
      final caudalTotal = caudal * emisores;
      _tiempoRiego = volumenAgua / (caudalTotal * eficiencia);
    } else {
      _tiempoRiego = null;
    }
  }

  double _calcularEToHargreaves(Map<String, dynamic> weatherData) {
    final tAvg = weatherData['temperature_avg'] ?? 0.0;
    final tMax = weatherData['temperature_max'] ?? 0.0;
    final tMin = weatherData['temperature_min'] ?? 0.0;
    final ra = _calcularRadiacionExtraterrestre(weatherData);
    return 0.0023 * (tAvg + 17.8) * pow((tMax - tMin), 0.5) * ra;
   // return 0.0023 * (tAvg + 17.8) * pow((tMax - tMin), 0.5) * ra;
  }

  double _calcularRadiacionExtraterrestre(Map<String, dynamic> weatherData) {
    const latitud = -35.4264;
    final diaDelAnio = _calcularDiaDelAnio();
    final phi = latitud * (pi / 180);
    final delta = 0.409 * sin((2 * pi / 365) * diaDelAnio - 1.39);
    final dr = 1 + 0.033 * cos((2 * pi / 365) * diaDelAnio);
    final omegaS = acos(-tan(phi) * tan(delta));
    const gsc = 0.0820;
    return (24 * 60 / pi) * gsc * dr *
        (omegaS * sin(phi) * sin(delta) + cos(phi) * cos(delta) * sin(omegaS));
  }

  int _calcularDiaDelAnio() {
    final now = DateTime.now();
    return now.difference(DateTime(now.year, 1, 1)).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Cuartel',
            style: TextStyle(color: colors.onPrimary)),
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
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoricoRiego(
                    nombreCuartel: widget.datos['nombre'] ?? 'Cuartel',
                    latitud: widget.weatherData?['latitude'] ?? -35.4264,
                    longitud: widget.weatherData?['longitude'] ?? -71.6554,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (widget.weatherData != null) ...[
                _buildWeatherSection(theme, colors),
                const SizedBox(height: 24),
              ],
              _buildCropSection(theme, colors),
              const SizedBox(height: 24),
              if (_tiempoRiego != null) _buildIrrigationTime(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherSection(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: colors.primary, size: 28),
                const SizedBox(width: 8),
                Text('Datos Meteorológicos',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const Divider(height: 32, thickness: 1),
            _buildWeatherRow(Icons.thermostat, 'Mínima',
                '${widget.weatherData!['temperature_min']?.toStringAsFixed(1) ?? 'N/A'}°C'),
            _buildWeatherRow(Icons.thermostat, 'Máxima',
                '${widget.weatherData!['temperature_max']?.toStringAsFixed(1) ?? 'N/A'}°C'),
            _buildWeatherRow(Icons.air, 'Viento',
                '${widget.weatherData!['wind_speed_max']?.toStringAsFixed(1) ?? 'N/A'} m/s'),
            const SizedBox(height: 16),
            _buildEnhancedValueChip(
              icon: Icons.wb_sunny_outlined,
              label: 'EVAPOTRANSPIRACIÓN (ETo)',

              value: '${_etoHargreaves?.toStringAsFixed(2) ?? 'N/A'}',
              unit: 'mm/día',
              color: Colors.blue.shade100,
              iconColor: Colors.blue.shade800,
            ),
            const SizedBox(height: 12),
            _buildEnhancedValueChip(
              icon: Icons.grass_outlined,
              label: 'REQUERIMIENTO HÍDRICO (ETc)',
              value: '${_etc?.toStringAsFixed(1) ?? 'N/A'}',
              unit: 'mm/día',
              color: Colors.green.shade100,
              iconColor: Colors.green.shade800,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedValueChip({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildCropSection(ThemeData theme, ColorScheme colors) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.spa, color: colors.secondary, size: 28),
                const SizedBox(width: 8),
                Text('Datos del Cultivo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField(
              controller: _controllerKc,
              label: 'Coeficiente de Cultivo (Kc)',
              icon: Icons.eco,
            ),
            _buildInputField(
              controller: _controllerCaudal,
              label: 'Caudal (L/Hr)',
              icon: Icons.water_drop,
            ),
            _buildInputField(
              controller: _controllerEmisores,
              label: 'Número de Emisores',
              icon: Icons.format_list_numbered,
            ),
            _buildInputField(
              controller: _controllerEntre,
              label: 'distancia entre hilera  (m²)',
              icon: Icons.square_foot,
            ),
            _buildInputField(
              controller: _controllerSobre,
              label: 'distancia sobre hilera  (m²)',
              icon: Icons.square_foot,
            ),
            _buildTipoRiegoDropdown(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoRiegoDropdown(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<TipoRiego>(
        value: _tipoRiego,
        decoration: InputDecoration(
          labelText: 'Tipo de Riego',
          prefixIcon: Icon(Icons.water, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: _tipoRiego.tecnificado
              ? Colors.green.shade50
              : Colors.orange.shade50,
        ),
        isExpanded: true,
        items: TipoRiego.values.map((TipoRiego tipo) {
          return DropdownMenuItem<TipoRiego>(
            value: tipo,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 100),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tipo.tecnificado ? Icons.engineering : Icons.agriculture,
                      color: tipo.tecnificado ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        tipo.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tipo.tecnificado) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Tecnificado',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: (TipoRiego? newValue) {
          if (newValue != null) {
            setState(() {
              _tipoRiego = newValue;
              _recalcularETo();
            });
          }
        },
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) => _recalcularETo(),
      ),
    );
  }

  Widget _buildIrrigationTime(ColorScheme colors) {
    final isTecnificado = _tipoRiego.tecnificado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTecnificado
            ? Colors.green.shade100
            : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isTecnificado
              ? Colors.green.shade300
              : Colors.orange.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isTecnificado
                        ? Icons.engineering
                        : Icons.agriculture,
                    color: isTecnificado ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _tipoRiego.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isTecnificado ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              Chip(
                backgroundColor: isTecnificado
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
                label: Text(
                  'Eficiencia: ${(_eficienciaRiego[_tipoRiego]! * 100).toInt()}%',
                  style: TextStyle(
                    color: isTecnificado
                        ? Colors.green.shade900
                        : Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time_filled,
                  size: 40,
                  color: isTecnificado ? Colors.green : Colors.orange),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tiempo de riego recomendado',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700)),
                    Text('${_tiempoRiego!.toStringAsFixed(1)} horas',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isTecnificado
                                ? Colors.green.shade800
                                : Colors.orange.shade800)),
                  ],
                ),
              ),
            ],
          ),
          if (!isTecnificado) ...[
            const SizedBox(height: 12),
            Text(
              'Considera actualizar a un sistema tecnificado para mayor eficiencia',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}