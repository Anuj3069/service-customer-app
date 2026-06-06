/// API Configuration — Base URL and endpoint constants
class ApiConfig {
  // Production backend URL (deployed on Render)
  static const String baseUrl = 'https://service-app-rduc.onrender.com/api/v1';

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
  static String bookingOtp(String id) => '/user/bookings/$id/otp';
  static String bookingChat(String id) => '/user/bookings/$id/chat';

  // Instant Booking
  static const String instantBooking = '/user/instant-booking';

  // Reviews
  static const String reviews = '/user/reviews';

  // Nearby Workers
  static const String nearbyWorkers = '/user/nearby-workers';

  // Payments
  static String payBooking(String id) => '/user/bookings/$id/pay';
  static String payBookingCash(String id) => '/user/bookings/$id/pay-cash';
  static String verifyPayment(String id) => '/payments/$id/verify';

}
