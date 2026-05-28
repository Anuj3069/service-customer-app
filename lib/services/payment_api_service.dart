import '../config/api_config.dart';
import 'api_client.dart';

class PaymentApiService {
  /// Initiate a Cashfree payment order for a completed booking.
  /// Returns a map containing the payment details (like orderId and paymentSessionId).
  Future<Map<String, dynamic>> initiatePayment(String bookingId) async {
    final response = await ApiClient.post(ApiConfig.payBooking(bookingId), {});
    final data = response['data'];
    
    if (data != null && data['payment'] != null) {
      return Map<String, dynamic>.from(data['payment']);
    }
    throw ApiException('Failed to retrieve payment details from server', 500);
  }

  /// Verify Cashfree payment status after the client SDK checkout finishes.
  /// Returns a map containing status (e.g. 'paid', 'failed', 'pending') and orderId.
  Future<Map<String, dynamic>> verifyPayment(String bookingId) async {
    final response = await ApiClient.post(ApiConfig.verifyPayment(bookingId), {});
    final data = response['data'];
    
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    throw ApiException('Failed to verify payment status with server', 500);
  }
}
