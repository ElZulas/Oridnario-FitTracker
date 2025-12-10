import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/weather.dart';
import '../repositories/weather_repository.dart';

class GetCurrentWeather implements UseCase<Weather, GetCurrentWeatherParams> {
  final WeatherRepository repository;

  GetCurrentWeather(this.repository);

  @override
  Future<Either<Failure, Weather>> call(GetCurrentWeatherParams params) async {
    return await repository.getCurrentWeather(
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class GetCurrentWeatherParams {
  final double latitude;
  final double longitude;

  GetCurrentWeatherParams({
    required this.latitude,
    required this.longitude,
  });
}


