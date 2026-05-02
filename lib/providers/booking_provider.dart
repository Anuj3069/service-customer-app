import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/match_result.dart';
import '../services/booking_api_service.dart';
import '../services/match_api_service.dart';
import '../services/review_api_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingApiService _bookingApi = BookingApiService();
  final MatchApiService _matchApi = MatchApiService();
  final ReviewApiService _reviewApi = ReviewApiService();

  List<Booking> _bookings = [];
  Booking? _selectedBooking;
  MatchResult? _matchResult;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  List<Booking> get bookings => _bookings;
  Booking? get selectedBooking => _selectedBooking;
  MatchResult? get matchResult => _matchResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  /// Find a matching provider
  Future<bool> findMatch({
    required String serviceId,
    required String date,
    required String slot,
  }) async {
    _isLoading = true;
    _error = null;
    _matchResult = null;
    notifyListeners();

    try {
      _matchResult = await _matchApi.findMatch(
        serviceId: serviceId,
        date: date,
        slot: slot,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a booking from match result
  Future<bool> createBooking() async {
    if (_matchResult == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final booking = await _bookingApi.createBooking(
        providerId: _matchResult!.provider.id,
        serviceId: _matchResult!.service.id,
        date: _matchResult!.date,
        slot: _matchResult!.slot,
        price: _matchResult!.price,
      );
      _selectedBooking = booking;
      _successMessage = 'Booking created successfully!';
      _matchResult = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a booking directly when provider/service details are already known
  Future<bool> createDirectBooking({
    required String providerId,
    required String serviceId,
    required String date,
    required String slot,
    required double price,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final booking = await _bookingApi.createBooking(
        providerId: providerId,
        serviceId: serviceId,
        date: date,
        slot: slot,
        price: price,
      );
      _selectedBooking = booking;
      _successMessage = 'Booking created successfully!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch user bookings
  Future<void> fetchBookings({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bookings = await _bookingApi.getBookings(status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get booking by ID
  Future<void> fetchBookingById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedBooking = await _bookingApi.getBookingById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit a review
  Future<bool> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _reviewApi.createReview(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
      );
      _successMessage = 'Review submitted successfully!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMatchResult() {
    _matchResult = null;
    notifyListeners();
  }
}
