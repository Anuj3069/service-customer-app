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

  /// Cancel a requested/pending booking
  Future<Booking> cancelBooking(String id, {String? cancellationReason}) async {
    final response = await ApiClient.put(ApiConfig.cancelBooking(id), {
      if (cancellationReason != null && cancellationReason.trim().isNotEmpty)
        'cancellationReason': cancellationReason.trim(),
    });
    final data = response['data'];

    if (data['booking'] != null) {
      return Booking.fromJson(data['booking']);
    }
    return Booking.fromJson(data);
  }

  /// Create a month-long booking contract
  Future<Map<String, dynamic>> createMonthBooking({
    required String providerId,
    required String serviceId,
    required String monthStartDate,
    Map<String, dynamic>? customerLocation,
  }) async {
    final response = await ApiClient.post(ApiConfig.monthBooking, {
      'providerId': providerId,
      'serviceId': serviceId,
      'monthStartDate': monthStartDate,
      if (customerLocation != null) 'customerLocation': customerLocation,
    });
    return response['data'] as Map<String, dynamic>;
  }

  /// Get the daily schedule (child bookings) for a month contract
  Future<List<Booking>> getMonthBookingSchedule(String masterId) async {
    final response = await ApiClient.get(ApiConfig.bookingSchedule(masterId));
    final data = response['data'];
    if (data['children'] != null) {
      return (data['children'] as List).map((j) => Booking.fromJson(j)).toList();
    }
    return [];
  }

  /// Cancel a booking; pass scope='ALL' to cancel the whole month contract
  Future<Booking> cancelBookingWithScope(
    String id, {
    String? cancellationReason,
    String scope = 'THIS',
  }) async {
    final response = await ApiClient.put(ApiConfig.cancelBooking(id), {
      if (cancellationReason != null && cancellationReason.trim().isNotEmpty)
        'cancellationReason': cancellationReason.trim(),
      'cancellationScope': scope,
    });
    final data = response['data'];
    if (data['booking'] != null) return Booking.fromJson(data['booking']);
    return Booking.fromJson(data);
  }

  /// Get the completion OTP for an accepted booking (customer-only)
  Future<String> getCompletionOtp(String bookingId) async {
    final response = await ApiClient.get(ApiConfig.bookingOtp(bookingId));
    final data = response['data'];
    return data['otp']?.toString() ?? '';
  }
}
