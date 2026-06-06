import '../config/api_config.dart';
import '../models/booking.dart';
import 'api_client.dart';

class BookingApiService {
  /// Create a new scheduled booking
  Future<Booking> createBooking({
    required String providerId,
    required String serviceId,
    required String date,
    required String slot,
    required double price,
    Map<String, dynamic>? customerLocation,
  }) async {
    final response = await ApiClient.post(ApiConfig.bookings, {
      'providerId': providerId,
      'serviceId': serviceId,
      'date': date,
      'slot': slot,
      'price': price,
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
    Map<String, dynamic>? customerLocation,
  }) async {
    final response = await ApiClient.post(ApiConfig.instantBooking, {
      'serviceId': serviceId,
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

}
