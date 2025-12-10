class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://hiqtcguhxcnrnspwjvag.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpcXRjZ3VoeGNucm5zcHdqdmFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUzNTY5MTAsImV4cCI6MjA4MDkzMjkxMH0.yj5Gm_PRAF7DZNe7STOm2ZxVGlTJhdOaLhDadXQQvQw';
  
  // Weather API Configuration
  // ⚠️ INSTRUCCIONES PARA CONFIGURAR LA API KEY:
  // 1. Ve a https://openweathermap.org/api y crea una cuenta (es gratis)
  // 2. Inicia sesión y ve a "API keys" en tu perfil
  // 3. Copia tu API key y reemplaza 'TU_WEATHER_API_KEY_AQUI' con tu clave
  // 4. El plan gratuito incluye 1,000 llamadas API por día
  // 
  // Ejemplo: static const String weatherApiKey = 'abc123def456ghi789';
  static const String weatherApiKey = 'e421a869282dd0e7986a8ab67d284e88';
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
