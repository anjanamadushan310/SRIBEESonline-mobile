/// SRIBEESonline Flutter App - Environment Configuration
/// 
/// This file provides environment-specific configuration for the mobile app.
/// Different environments: development, staging, production

enum Environment {
  development,
  staging,
  production,
}

/// SharedPreferences key for the user-saved custom API base URL.
const kCustomApiUrlKey = 'custom_api_url';

class AppConfig {
  static late Environment _environment;
  static late AppConfig _instance;

  final String appName;
  String apiBaseUrl; // mutable so updateApiUrl() can patch it at runtime
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

  /// Initialize app configuration based on environment.
  ///
  /// Pass [customApiUrl] (read from SharedPreferences in main()) to override
  /// the hardcoded default — required when running on a physical device.
  static void initialize(Environment env, {String? customApiUrl}) {
    _environment = env;

    switch (env) {
      case Environment.development:
        _instance = AppConfig._(
          appName: 'SRIBEESonline (Dev)',
          // customApiUrl is set by the user via ServerConfigScreen and
          // persisted in SharedPreferences under kCustomApiUrlKey.
          apiBaseUrl: customApiUrl ?? 'http://10.0.2.2:8000/api/v1',
          sentryDsn: '',
          enableLogging: true,
          enableCrashlytics: false,
          sentryTracesSampleRate: 0.0,
        );
        break;

      case Environment.staging:
        _instance = AppConfig._(
          appName: 'SRIBEESonline (Staging)',
          apiBaseUrl: customApiUrl ?? 'https://api-staging.sribeesonline.lk/api/v1',
          sentryDsn: 'https://your-staging-dsn@sentry.io/project',
          enableLogging: true,
          enableCrashlytics: true,
          sentryTracesSampleRate: 0.5,
        );
        break;

      case Environment.production:
        _instance = AppConfig._(
          appName: 'SRIBEESonline',
          apiBaseUrl: customApiUrl ?? 'https://api.sribees.com/api/v1',
          sentryDsn: 'https://your-production-dsn@sentry.io/project',
          enableLogging: false,
          enableCrashlytics: true,
          sentryTracesSampleRate: 0.1,
        );
        break;
    }
  }

  /// Update the API base URL at runtime (called from ServerConfigScreen after
  /// the user saves a new address). Existing Riverpod providers that have
  /// already built an ApiClient will be invalidated by the caller.
  static void updateApiUrl(String url) {
    _instance.apiBaseUrl = url;
  }

  static String get apiUrl => _instance.apiBaseUrl;
}
