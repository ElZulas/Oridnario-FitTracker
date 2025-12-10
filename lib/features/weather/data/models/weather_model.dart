class WeatherModel {
  final String description;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final String main;

  WeatherModel({
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.main,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      description: json['weather'][0]['description'] as String,
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'] as int,
      main: json['weather'][0]['main'] as String,
    );
  }

  String getActivityRecommendation() {
    switch (main.toLowerCase()) {
      case 'rain':
      case 'drizzle':
        return 'Actividades indoor: Gimnasio, Yoga';
      case 'snow':
        return 'Actividades indoor: Gimnasio, Yoga';
      case 'extreme':
        return 'Evita actividades al aire libre';
      case 'clear':
        return 'Perfecto para actividades al aire libre: Correr, Caminar, Ciclismo';
      default:
        return 'Actividades moderadas recomendadas';
    }
  }
}


