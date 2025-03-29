import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://api.open-meteo.com/v1/forecast';

  /// Obtiene los datos meteorológicos para una ubicación específica
  Future<Map<String, dynamic>?> fetchWeatherData({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Construye la URL con los parámetros necesarios
      final url = Uri.parse('$baseUrl?latitude=$latitude&longitude=$longitude'
          '&hourly=temperature_2m,wind_speed_10m'
          '&daily=temperature_2m_max,temperature_2m_min,wind_speed_10m_max,wind_gusts_10m_max,et0_fao_evapotranspiration,shortwave_radiation_sum'
          '&timezone=auto&past_days=7&forecast_days=1');

      // Realiza la solicitud HTTP
      final response = await http.get(url);

      // Verifica si la solicitud fue exitosa
      if (response.statusCode == 200) {
        // Decodifica la respuesta JSON
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Procesa los datos para extraer la información requerida
        return _processWeatherData(jsonData);
      } else {
        print("Error al obtener datos meteorológicos: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Excepción al obtener datos meteorológicos: $e");
      return null;
    }
  }
  Future<Map<String, dynamic>> obtenerHistoricoMeteorologico(double latitud, double longitud) async {
    final response = await http.get(
      Uri.parse('https://api.open-meteo.com/v1/forecast?'
          'latitude=$latitud&longitude=$longitud'
          '&daily=temperature_2m_max,temperature_2m_min,wind_speed_10m_max,wind_gusts_10m_max,et0_fao_evapotranspiration,shortwave_radiation_sum'
          '&timezone=auto'
          '&past_days=7'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar datos históricos');
    }
  }
  /// Procesa los datos JSON para extraer la información relevante
  Map<String, dynamic> _processWeatherData(Map<String, dynamic> jsonData) {
    // Extrae los datos diarios
    final Map<String, dynamic> dailyData = jsonData['daily'];

    // Extrae las temperaturas
    final List<double> maxTemps = List<double>.from(dailyData['temperature_2m_max']);
    final List<double> minTemps = List<double>.from(dailyData['temperature_2m_min']);
    final double avgTemp = (maxTemps.reduce((a, b) => a + b) + minTemps.reduce((a, b) => a + b)) / (maxTemps.length + minTemps.length);

    // Extrae las velocidades del viento
    final List<double> windSpeeds = List<double>.from(dailyData['wind_speed_10m_max']);
    final List<double> windGusts = List<double>.from(dailyData['wind_gusts_10m_max']);

    // Extrae la evapotranspiración de referencia (ETo) y la radiación solar
    final List<double>et0 = List<double>.from(dailyData['et0_fao_evapotranspiration']);
    final List<double> shortwaveRadiation = List<double>.from(dailyData['shortwave_radiation_sum']);

    // Devuelve un mapa con los datos procesados
    return {
      'temperature_min': minTemps.last, // Temperatura mínima del primer día
      'temperature_max': maxTemps.last, // Temperatura máxima del primer día
      'temperature_avg': avgTemp,        // Temperatura promedio
      'wind_speed_max': windSpeeds.last, // Velocidad máxima del viento del primer día
      'wind_gust_max': windGusts.last,   // Ráfaga máxima del viento del primer día
      'et0_fao_evapotranspiration': et0.last, // Evapotranspiración de referencia del primer día
      'shortwave_radiation_sum': shortwaveRadiation.last, // Radiación solar del primer día
    };
  }
}