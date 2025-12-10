import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/constants/app_constants.dart';

abstract class WeatherRemoteDataSource {
  Future<Map<String, dynamic>> getCurrentWeather({
    required double latitude,
    required double longitude,
  });
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final Dio dio;
  static const String _lastRequestTimeKey = 'weather_last_request_time';
  static const String _cachedWeatherKey = 'weather_cached_data';

  WeatherRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Rate limiting: 1 request cada 10 minutos
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    
    // Verificar si hay un caché guardado
    final lastRequestTimeString = prefs.getString(_lastRequestTimeKey);
    final cachedWeatherString = prefs.getString(_cachedWeatherKey);
    
    if (lastRequestTimeString != null && cachedWeatherString != null) {
      try {
        final lastRequestTime = DateTime.parse(lastRequestTimeString);
        final minutesSinceLastRequest = now.difference(lastRequestTime).inMinutes;
        
        // Si han pasado menos de 10 minutos, devolver el caché
        if (minutesSinceLastRequest < 10) {
          final cachedData = json.decode(cachedWeatherString) as Map<String, dynamic>;
          return cachedData;
        }
      } catch (e) {
        // Si hay error al parsear, continuar con la solicitud nueva
      }
    }

    // Validar que la API key esté configurada
    if (AppConstants.weatherApiKey == 'TU_WEATHER_API_KEY_AQUI' ||
        AppConstants.weatherApiKey.isEmpty) {
      throw Exception(
        'API key de OpenWeatherMap no configurada. '
        'Por favor configura tu API key en app_constants.dart. '
        'Obtén una API key gratuita en: https://openweathermap.org/api',
      );
    }

    try {
      final response = await dio.get(
        '${AppConstants.weatherBaseUrl}/weather',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': AppConstants.weatherApiKey,
          'units': 'metric',
        },
      );

      // Guardar la respuesta en caché con timestamp
      final weatherData = response.data as Map<String, dynamic>;
      await prefs.setString(_lastRequestTimeKey, now.toIso8601String());
      await prefs.setString(_cachedWeatherKey, json.encode(weatherData));
      
      return weatherData;
    } catch (e) {
      // Si hay un error de autenticación, es probable que la API key sea inválida
      if (e.toString().contains('401') || e.toString().contains('Invalid API key')) {
        throw Exception(
          'API key de OpenWeatherMap inválida. '
          'Por favor verifica tu API key en app_constants.dart',
        );
      }
      
      // Si hay un error pero tenemos caché antiguo, devolverlo
      if (cachedWeatherString != null) {
        try {
          final cachedData = json.decode(cachedWeatherString) as Map<String, dynamic>;
          return cachedData;
        } catch (_) {
          // Si el caché está corrupto, continuar con el error
        }
      }
      
      rethrow;
    }
  }
}


