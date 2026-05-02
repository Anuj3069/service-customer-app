/// API Configuration — Base URL and endpoint constants
class ApiConfig {
  // Use 10.0.2.2 for Android emulator (maps to host machine's localhost)
  static const String baseUrl = 'http://10.0.2.2:3000/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Services
  static const String services = '/user/services';
  static String serviceById(String id) => '/user/services/$id';

  // Match
  static const String match = '/user/match';

  // Bookings
  static const String bookings = '/user/bookings';
  static String bookingById(String id) => '/user/bookings/$id';

  // Reviews
  static const String reviews = '/user/reviews';
}
