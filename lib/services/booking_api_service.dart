import '../config/api_config.dart';
import '../models/booking.dart';
import 'api_client.dart';

/// Result returned by the backend promo validation endpoint
class PromoValidationResult {
  final String code;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double finalPrice;
  final String message;

  PromoValidationResult({
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.finalPrice,
    required this.message,
  });

  factory PromoValidationResult.fromJson(Map<String, dynamic> json) {
    return PromoValidationResult(
      code: json['code'] ?? '',
      discountType: json['discountType'] ?? 'flat',
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalPrice: (json['finalPrice'] ?? 0).toDouble(),
      message: json['message'] ?? '',
    );
  }
}

class BookingApiService {
  /// Create a new scheduled booking
  Future<Booking> createBooking({
    required String providerId,
    required String serviceId,
    required String date,
    required String slot,
    required double price,
    String? promoCode,
    Map<String, dynamic>? customerLocation,
  }) async {
    final response = await ApiClient.post(ApiConfig.bookings, {
      'providerId': providerId,
      'serviceId': serviceId,
      'date': date,
      'slot': slot,
      'price': price,
      if (promoCode != null) 'promoCode': promoCode,
      if (customerLocation != null) 'customerLocation': customerLocation,
    });

    final data = response['data'];
    if (data['booking'] != null) {
      return Booking.fromJson(data['booking']);
    }
    return Booking.fromJson(data);
  }

  /// Create an instant booking (Uber-style broadcast to workers)
  Future<Booking> createInstantBooking({
    required String serviceId,
    String? promoCode,
    Map<String, dynamic>? customerLocation,
  }) async {
    final response = await ApiClient.post(ApiConfig.instantBooking, {
      'serviceId': serviceId,
      if (promoCode != null) 'promoCode': promoCode,
      if (customerLocation != null) 'customerLocation': customerLocation,
    });

    final data = response['data'];
    if (data['booking'] != null) {
      return Booking.fromJson(data['booking']);
    }
    return Booking.fromJson(data);
  }

  /// Get all bookings for current user
  Future<List<Booking>> getBookings({String? status}) async {
    String endpoint = ApiConfig.bookings;
    if (status != null && status.isNotEmpty) {
      endpoint += '?status=$status';
    }

    final response = await ApiClient.get(endpoint);
    final data = response['data'];

    if (data['bookings'] != null) {
      return (data['bookings'] as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Get booking by ID
  Future<Booking> getBookingById(String id) async {
    final response = await ApiClient.get(ApiConfig.bookingById(id));
    final data = response['data'];

    if (data['booking'] != null) {
      return Booking.fromJson(data['booking']);
    }
    return Booking.fromJson(data);
  }

  /// Get the completion OTP for an accepted booking (customer-only)
  Future<String> getCompletionOtp(String bookingId) async {
    final response = await ApiClient.get(ApiConfig.bookingOtp(bookingId));
    final data = response['data'];
    return data['otp']?.toString() ?? '';
  }

  /// Validate a promo code against a service price
  Future<PromoValidationResult> validatePromoCode({
    required String code,
    required double price,
    String? serviceId,
  }) async {
    final response = await ApiClient.post(ApiConfig.validatePromo, {
      'code': code.toUpperCase(),
      'price': price,
      if (serviceId != null) 'serviceId': serviceId,
    });
    final data = response['data'];
    return PromoValidationResult.fromJson({
      'code': code.toUpperCase(),
      ...data,
    });
  }
}
