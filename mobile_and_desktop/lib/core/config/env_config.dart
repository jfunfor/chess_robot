// lib/core/config/env_config.dart
class EnvConfig {
  static final bool useMock =
      const bool.fromEnvironment('USE_MOCK', defaultValue: false);

  static final String apiBaseUrl = useMock
      ? 'http://localhost:3000' // Mockoon服务器
      : ''; // 生产环境不使用HTTP
}
