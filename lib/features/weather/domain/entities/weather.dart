import 'package:equatable/equatable.dart';

class Weather extends Equatable {
  final String description;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String main;
  final String activityRecommendation;

  const Weather({
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.main,
    required this.activityRecommendation,
  });

  @override
  List<Object?> get props => [
        description,
        temperature,
        feelsLike,
        humidity,
        main,
        activityRecommendation,
      ];
}


