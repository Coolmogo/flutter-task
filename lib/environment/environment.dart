class EnvironmentConfig {
  final String name;
  final String apiBaseUrl;
  final bool isDebug;
  final bool useMockData;

  const EnvironmentConfig({
    required this.name,
    required this.apiBaseUrl,
    required this.isDebug,
    required this.useMockData,
  });
}

class Environment {
  Environment._();

  static const prod = 'PROD';
  static const dev = 'DEV';
  static const design = 'DESIGN';
  static const devApiBaseUrl = 'https://task-mcp-cli-tool.onrender.com';
  static const prodApiBaseUrl = 'https://task-mcp-cli-tool.onrender.com';

  static final Environment _instance = Environment._();

  factory Environment() => _instance;

  EnvironmentConfig _config = const EnvironmentConfig(
    name: design,
    apiBaseUrl: devApiBaseUrl,
    isDebug: true,
    useMockData: false,
  );

  EnvironmentConfig get config => _config;

  void initConfig(String env) {
    switch (env.toUpperCase()) {
      case prod:
        _config = const EnvironmentConfig(
          name: prod,
          apiBaseUrl: prodApiBaseUrl,
          isDebug: false,
          useMockData: false,
        );
        return;
      case dev:
        _config = const EnvironmentConfig(
          name: dev,
          apiBaseUrl: devApiBaseUrl,
          isDebug: true,
          useMockData: false,
        );
        return;
      case design:
      default:
        _config = const EnvironmentConfig(
          name: design,
          apiBaseUrl: devApiBaseUrl,
          isDebug: true,
          useMockData: false,
        );
    }
  }
}
