/// Application configuration for different environments
class AppConfig {
  static const bool useMockData =
      false; // Set to true to use mock data for offline demo
  static const bool enableNetworkLogs = true;
  static const Duration networkTimeout = Duration(seconds: 10);

  // API endpoints
  static const String baseUrl = 'https://jsonplaceholder.typicode.com/';
  static const String alternativeBaseUrl = 'https://dummyjson.com/';

  // Mock data configuration
  static const Duration mockDelay = Duration(milliseconds: 500);
  static const double mockErrorRate = 0.1; // 10% chance of mock errors
}
