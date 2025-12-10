import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';

abstract class WeatherRemoteDataSource {
  Future<Map<String, dynamic>> getCurrentWeather({
    required double latitude,
    required double longitude,
  });
}

class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final Dio dio;
  DateTime? lastRequestTime;
  Map<String, dynamic>? cachedWeather;

  WeatherRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Rate limiting: 1 request cada 10 minutos
    final now = DateTime.now();
    if (lastRequestTime != null &&
        cachedWeather != null &&
        now.difference(lastRequestTime!).inMinutes < 10) {
      return cachedWeather!;
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

      lastRequestTime = now;
      cachedWeather = response.data as Map<String, dynamic>;
      return cachedWeather!;
    } catch (e) {
      if (cachedWeather != null) {
        return cachedWeather!;
      }
      rethrow;
    }
  }
}


