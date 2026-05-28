/// SRIBEESonline Flutter App - Environment Configuration
/// 
/// This file provides environment-specific configuration for the mobile app.
/// Different environments: development, staging, production

enum Environment {
  development,
  staging,
  production,
}

class AppConfig {
  static late Environment _environment;
  static late AppConfig _instance;
  
  final String appName;
  final String apiBaseUrl;
  final String sentryDsn;
  final bool enableLogging;
  final bool enableCrashlytics;
  final double sentryTracesSampleRate;
  
  AppConfig._({
    required this.appName,
    required this.apiBaseUrl,
    required this.sentryDsn,
    required this.enableLogging,
    required this.enableCrashlytics,
    required this.sentryTracesSampleRate,
  });
  
  static Environment get environment => _environment;
  static AppConfig get instance => _instance;
  static bool get isDevelopment => _environment == Environment.development;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProduction => _environment == Environment.production;
  
  /// Initialize app configuration based on environment
  static void initialize(Environment env) {
    _environment = env;
    
    switch (env) {
      case Environment.development:
        _instance = AppConfig._(
          appName: 'SRIBEESonline (Dev)',
          // Use 10.0.2.2 for Android Emulator (maps to host's localhost)
          // Use localhost for iOS Simulator
          // Use your computer's IP (e.g., 192.168.1.100) for physical devices
          apiBaseUrl: 'http://10.0.2.2:8000/api/v1',
          sentryDsn: '', // No Sentry in development
          enableLogging: true,
          enableCrashlytics: false,
          sentryTracesSampleRate: 0.0,
        );
        break;
        
      case Environment.staging:
        _instance = AppConfig._(
          appName: 'SRIBEESonline (Staging)',
          apiBaseUrl: 'https://api-staging.sribeesonline.lk/api/v1',
          sentryDsn: 'https://your-staging-dsn@sentry.io/project',
          enableLogging: true,
          enableCrashlytics: true,
          sentryTracesSampleRate: 0.5,
        );
        break;
        
      case Environment.production:
        _instance = AppConfig._(
          appName: 'SRIBEESonline',
          apiBaseUrl: 'https://api.sribeesonline.lk/api/v1',
          sentryDsn: 'https://your-production-dsn@sentry.io/project',
          enableLogging: false,
          enableCrashlytics: true,
          sentryTracesSampleRate: 0.1,
        );
        break;
    }
  }
  
  /// Get configuration value with fallback
  static String get apiUrl => _instance.apiBaseUrl;
}
