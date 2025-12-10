# FitTracker - Aplicación de Seguimiento Fitness con Metas

Aplicación Flutter para registrar actividades físicas diarias, establecer metas semanales y visualizar progreso con gráficos.

## Características

- ✅ Autenticación con Supabase (registro, login, verificación de email)
- ✅ Onboarding inicial con datos del usuario
- ✅ Registro de actividades físicas (CRUD completo)
- ✅ Sistema de metas semanales con seguimiento de progreso
- ✅ Dashboard con estadísticas y gráficos
- ✅ Integración con Weather API para recomendaciones
- ✅ Calendario mensual con indicadores de actividad
- ✅ Exportación de datos a CSV
- ✅ Navegación con go_router y deep linking
- ✅ Animaciones Lottie para celebraciones

## Tecnologías Utilizadas

- **Estado**: Cubit (bloc package)
- **Navegación**: go_router con deep linking
- **Base de datos**: Supabase
- **HTTP**: Dio para Weather API
- **Gráficos**: fl_chart
- **Animaciones**: Lottie
- **Arquitectura**: Clean Architecture

## Configuración Inicial

### 1. Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com)
2. Ejecuta el script SQL en `supabase/schema.sql` para crear las tablas
3. Actualiza las credenciales en `lib/core/constants/app_constants.dart`:
   ```dart
   static const String supabaseUrl = 'TU_SUPABASE_URL';
   static const String supabaseAnonKey = 'TU_SUPABASE_ANON_KEY';
   ```

### 2. Configurar Weather API

1. Obtén una API key de [OpenWeatherMap](https://openweathermap.org/api)
2. Actualiza en `lib/core/constants/app_constants.dart`:
   ```dart
   static const String weatherApiKey = 'TU_WEATHER_API_KEY';
   ```

### 3. Instalar Dependencias

```bash
cd fit_tracker
flutter pub get
```

### 4. Agregar Animaciones Lottie

Descarga animaciones Lottie y colócalas en `assets/animations/`:
- `fitness.json` - Para splash screen
- `onboarding1.json`, `onboarding2.json`, `onboarding3.json` - Para onboarding
- `celebration.json` - Para celebración de metas

Puedes descargar animaciones gratuitas de [LottieFiles](https://lottiefiles.com)

### 5. Ejecutar la Aplicación

```bash
flutter run
```

## Estructura del Proyecto

```
lib/
├── core/
│   ├── constants/      # Constantes de la aplicación
│   ├── errors/          # Clases de error
│   ├── navigation/      # Configuración de rutas
│   ├── usecases/        # UseCase base
│   └── utils/           # Utilidades
└── features/
    ├── auth/            # Autenticación
    ├── onboarding/      # Onboarding
    ├── activities/      # Actividades
    ├── goals/           # Metas semanales
    ├── dashboard/       # Dashboard principal
    ├── weather/         # Integración con Weather API
    └── profile/         # Perfil de usuario
```

## Base de Datos Supabase

### Tablas Requeridas

1. **user_profiles**: Perfil del usuario
2. **activities**: Actividades físicas
3. **weekly_goals**: Metas semanales

Ver `supabase/schema.sql` para el esquema completo.

## Deep Linking

La aplicación soporta deep linking con el formato:
```
fittracker://activity?id={activity_id}
```

## Testing

Ejecutar tests unitarios:
```bash
flutter test
```

## Commits Requeridos

El proyecto sigue estos commits principales:
1. chore: project setup with dependencies
2. feat(auth): implement authentication with supabase
3. feat(onboarding): add user onboarding flow
4. feat(activities): create activity crud operations
5. feat(goals): implement weekly goals system
6. feat(dashboard): add statistics dashboard
7. feat(charts): integrate fl_chart for visualizations
8. feat(api): integrate weather api with dio
9. feat(navigation): configure go_router with deep linking
10. feat(animations): add lottie animations
11. test: add unit tests for cubits
12. docs: complete documentation and readme

## Notas Importantes

- Las actividades solo pueden editarse el día actual
- El rate limiting de Weather API es de 1 request cada 10 minutos
- La validación de duración es entre 1-480 minutos
- La validación de distancia es entre 0-999 km
- El cálculo de racha considera días consecutivos con actividad

## Licencia

Este proyecto es parte de un caso de prueba académico.
