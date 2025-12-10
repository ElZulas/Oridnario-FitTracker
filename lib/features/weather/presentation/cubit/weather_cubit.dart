import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/weather.dart';
import '../../domain/usecases/get_current_weather.dart';

part 'weather_state.dart';

class WeatherCubit extends Cubit<WeatherState> {
  final GetCurrentWeather getCurrentWeather;

  WeatherCubit({required this.getCurrentWeather}) : super(WeatherInitial());

  Future<void> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    emit(WeatherLoading());
    final result = await getCurrentWeather(GetCurrentWeatherParams(
      latitude: latitude,
      longitude: longitude,
    ));

    result.fold(
      (failure) => emit(WeatherError(failure.message)),
      (weather) => emit(WeatherLoaded(weather)),
    );
  }
}


