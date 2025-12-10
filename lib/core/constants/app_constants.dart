class AppConstants {
  // Supabase Configuration (debe ser configurado con tus credenciales)
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  // Weather API Configuration
  static const String weatherApiKey = 'YOUR_WEATHER_API_KEY';
  static const String weatherBaseUrl = 'https://api.openweathermap.org/data/2.5';
  static const Duration weatherCacheDuration = Duration(minutes: 10);
  
  // Activity Types
  static const List<String> activityTypes = [
    'Correr',
    'Caminar',
    'Ciclismo',
    'Natación',
    'Gimnasio',
    'Yoga',
  ];
  
  // Activity Levels
  static const List<String> activityLevels = [
    'sedentary',
    'light',
    'moderate',
    'active',
  ];
  
  // Validation Limits
  static const int minDurationMinutes = 1;
  static const int maxDurationMinutes = 480;
  static const double minDistanceKm = 0.0;
  static const double maxDistanceKm = 999.0;
  
  // Deep Linking
  static const String deepLinkScheme = 'fittracker';
  static const String deepLinkActivityPath = '/activity';
}


