import 'dart:async';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/match_result.dart';
import '../services/booking_api_service.dart';
import '../services/match_api_service.dart';
import '../services/review_api_service.dart';
import '../services/socket_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingApiService _bookingApi = BookingApiService();
  final MatchApiService _matchApi = MatchApiService();
  final ReviewApiService _reviewApi = ReviewApiService();
  final SocketService _socketService = SocketService();

  List<Booking> _bookings = [];
  Booking? _selectedBooking;
  MatchResult? _matchResult;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // ── Instant Booking State ──────────────────────────
  Booking? _instantBooking;
  String _instantStatus = 'idle'; // idle, searching, confirmed, expired
  Map<String, dynamic>? _confirmedProvider;

  StreamSubscription? _confirmedSub;
  StreamSubscription? _expiredSub;

  List<Booking> get bookings => _bookings;
  Booking? get selectedBooking => _selectedBooking;
  MatchResult? get matchResult => _matchResult;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  Booking? get instantBooking => _instantBooking;
  String get instantStatus => _instantStatus;
  Map<String, dynamic>? get confirmedProvider => _confirmedProvider;
  SocketService get socketService => _socketService;

  /// Initialize socket connection after login
  void connectSocket(String userId) {
    _socketService.connect(userId);
    _listenToSocketEvents();
  }

  /// Disconnect socket on logout
  void disconnectSocket() {
    _confirmedSub?.cancel();
    _expiredSub?.cancel();
    _socketService.disconnect();
  }

  void _listenToSocketEvents() {
    _confirmedSub?.cancel();
    _expiredSub?.cancel();

    _confirmedSub = _socketService.onBookingConfirmed.listen((data) {
      debugPrint('[BookingProvider] booking-confirmed event: $data');
      _instantStatus = 'confirmed';
      _confirmedProvider = data['provider'] is Map
          ? Map<String, dynamic>.from(data['provider'])
          : null;
      notifyListeners();
    });

    _expiredSub = _socketService.onBookingExpired.listen((data) {
      debugPrint('[BookingProvider] booking-expired event: $data');
      _instantStatus = 'expired';
      notifyListeners();
    });
  }

  /// ── Instant Booking ─────────────────────────────────
  Future<bool> createInstantBooking({required String serviceId}) async {
    _isLoading = true;
    _error = null;
    _instantStatus = 'searching';
    _confirmedProvider = null;
    notifyListeners();

    try {
      _instantBooking = await _bookingApi.createInstantBooking(
        serviceId: serviceId,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _instantStatus = 'idle';
      notifyListeners();
      return false;
    }
  }

  /// Reset instant booking state
  void resetInstantBooking() {
    _instantBooking = null;
    _instantStatus = 'idle';
    _confirmedProvider = null;
    notifyListeners();
  }

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

  @override
  void dispose() {
    _confirmedSub?.cancel();
    _expiredSub?.cancel();
    _socketService.dispose();
    super.dispose();
  }
}
