import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_datasource.dart';
import '../models/weather_model.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;

  WeatherRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Weather>> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final json = await remoteDataSource.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );
      final model = WeatherModel.fromJson(json);
      return Right(Weather(
        description: model.description,
        temperature: model.temperature,
        feelsLike: model.feelsLike,
        humidity: model.humidity,
        main: model.main,
        activityRecommendation: model.getActivityRecommendation(),
      ));
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }
}


