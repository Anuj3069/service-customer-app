import 'dart:async';
import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../models/match_result.dart';
import '../services/booking_api_service.dart';
import '../services/match_api_service.dart';
import '../services/review_api_service.dart';
import '../services/socket_service.dart';
import '../utils/location_helper.dart';

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

  // ── Instant Booking State ──────────────────────────────
  Booking? _instantBooking;
  String _instantStatus = 'idle'; // idle, searching, confirmed, expired
  Map<String, dynamic>? _confirmedProvider;

  // ── Live Tracking State ───────────────────────────────
  bool _isTracking = false;
  List<double>? _workerCoordinates;
  int? _lastLocationTimestamp;
  String? _trackingBookingId;

  // ── Real-time notification state ───────────────────
  bool _isSocketConnected = false;
  bool _refreshOnReconnect = false;
  List<Map<String, dynamic>> _realtimeNotifications = [];

  StreamSubscription? _confirmedSub;
  StreamSubscription? _expiredSub;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _rejectedSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _trackingStartedSub;
  StreamSubscription? _workerLocationSub;
  StreamSubscription? _paidSub;

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
  bool get isSocketConnected => _isSocketConnected;
  List<Map<String, dynamic>> get realtimeNotifications =>
      _realtimeNotifications;

  // ── Live Tracking Getters ──
  bool get isTracking => _isTracking;
  List<double>? get workerCoordinates => _workerCoordinates;
  int? get lastLocationTimestamp => _lastLocationTimestamp;
  String? get trackingBookingId => _trackingBookingId;

  /// Computed getters for booking categories
  List<Booking> get pendingBookings =>
      _bookings.where((b) => b.status == 'pending').toList();
  List<Booking> get acceptedBookings =>
      _bookings.where((b) => b.status == 'accepted').toList();
  List<Booking> get completedBookings =>
      _bookings.where((b) => b.status == 'completed').toList();

  /// Initialize socket connection after login
  void connectSocket(String userId) {
    _socketService.connect(userId);
    _listenToSocketEvents();
  }

  /// Disconnect socket on logout
  void disconnectSocket() {
    _confirmedSub?.cancel();
    _expiredSub?.cancel();
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _completedSub?.cancel();
    _connectionSub?.cancel();
    _trackingStartedSub?.cancel();
    _workerLocationSub?.cancel();
    _paidSub?.cancel();
    _socketService.disconnect();
    _isSocketConnected = false;
    _realtimeNotifications.clear();
    resetTracking();
    notifyListeners();
  }

  void _listenToSocketEvents() {
    _confirmedSub?.cancel();
    _expiredSub?.cancel();
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _completedSub?.cancel();
    _connectionSub?.cancel();
    _trackingStartedSub?.cancel();
    _workerLocationSub?.cancel();
    _paidSub?.cancel();

    // ── Connection state tracking ──
    _connectionSub = _socketService.onConnectionStateChanged.listen((
      connected,
    ) {
      _isSocketConnected = connected;

      if (connected && _refreshOnReconnect) {
        _refreshOnReconnect = false;
        fetchBookings();
        if (_selectedBooking != null) {
          fetchBookingById(_selectedBooking!.id);
        }
      }

      if (!connected) {
        _refreshOnReconnect = true;
      }

      notifyListeners();
    });

    // ── Instant booking confirmed ──
    _confirmedSub = _socketService.onBookingConfirmed.listen((data) {
      debugPrint('[BookingProvider] 🎉 booking-confirmed: $data');
      _instantStatus = 'confirmed';
      _confirmedProvider = data['provider'] is Map
          ? Map<String, dynamic>.from(data['provider'])
          : null;

      _addNotification(
        type: 'confirmed',
        title: 'Booking Confirmed!',
        message: 'A provider has accepted your instant booking',
        data: data,
      );

      notifyListeners();
    });

    // ── Booking expired (Redis TTL keyspace) ──
    _expiredSub = _socketService.onBookingExpired.listen((data) {
      debugPrint('[BookingProvider] ⏰ booking-expired: $data');
      _instantStatus = 'expired';
      if (_instantBooking?.id == data['bookingId']?.toString()) {
        _instantBooking = null;
      }

      _addNotification(
        type: 'expired',
        title: 'Booking Expired',
        message:
            data['message'] ?? 'No providers accepted your request in time.',
        data: data,
      );

      // Auto-refresh booking list
      fetchBookings();
      notifyListeners();
    });

    // ── Scheduled booking accepted by worker ──
    _acceptedSub = _socketService.onBookingAccepted.listen((data) {
      debugPrint('[BookingProvider] ✅ booking-accepted: $data');

      _addNotification(
        type: 'accepted',
        title: 'Booking Accepted!',
        message: 'Your scheduled booking has been accepted by the provider',
        data: data,
      );

      // Auto-refresh booking list to show updated status
      fetchBookings();
      notifyListeners();
    });

    // ── Scheduled booking rejected by worker ──
    _rejectedSub = _socketService.onBookingRejected.listen((data) {
      debugPrint('[BookingProvider] ❌ booking-rejected: $data');

      _addNotification(
        type: 'rejected',
        title: 'Booking Rejected',
        message:
            'Your booking has been rejected by the provider. Please try again.',
        data: data,
      );

      // Auto-refresh booking list
      fetchBookings();
      notifyListeners();
    });

    // ── Booking completed by worker ──
    _completedSub = _socketService.onBookingCompleted.listen((data) {
      debugPrint('[BookingProvider] 🎉 booking-completed: $data');

      _addNotification(
        type: 'completed',
        title: 'Service Completed!',
        message: 'Your booking has been completed. Please leave a review!',
        data: data,
      );

      // Auto-refresh booking list
      fetchBookings();
      notifyListeners();
    });

    // ── Live Tracking: Worker started driving ──
    _trackingStartedSub = _socketService.onTrackingStarted.listen((data) {
      debugPrint('[BookingProvider] 📍 tracking-started: $data');
      final bookingId = data['bookingId']?.toString();
      _isTracking = true;
      _trackingBookingId = bookingId;
      _workerCoordinates = null;
      _lastLocationTimestamp = null;

      _addNotification(
        type: 'tracking',
        title: 'Provider En Route!',
        message: 'Your provider is on the way to you',
        data: data,
      );

      notifyListeners();
    });

    // ── Live Tracking: Worker GPS update ──
    _workerLocationSub = _socketService.onWorkerLocation.listen((data) {
      debugPrint('[BookingProvider] 🗺️ worker-location: $data');
      final coords = data['coordinates'];
      if (coords is List && coords.length == 2) {
        _workerCoordinates = [
          (coords[0] as num).toDouble(),
          (coords[1] as num).toDouble(),
        ];
      }
      _lastLocationTimestamp = data['timestamp'] is int
          ? data['timestamp']
          : DateTime.now().millisecondsSinceEpoch;
      _trackingBookingId = data['bookingId']?.toString() ?? _trackingBookingId;

      notifyListeners();
    });

    // ── Payment confirmed ──
    _paidSub = _socketService.onBookingPaid.listen((data) {
      debugPrint('[BookingProvider] 💳 booking-paid: $data');

      _addNotification(
        type: 'paid',
        title: 'Payment Successful!',
        message: 'Your payment has been successfully verified.',
        data: data,
      );

      // Auto-refresh booking list and active selected booking
      fetchBookings();
      if (_selectedBooking != null &&
          _selectedBooking!.id == data['bookingId']) {
        fetchBookingById(_selectedBooking!.id);
      }
      notifyListeners();
    });
  }

  /// Add a real-time notification
  void _addNotification({
    required String type,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) {
    _realtimeNotifications.insert(0, {
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    });
    // Keep only last 20 notifications
    if (_realtimeNotifications.length > 20) {
      _realtimeNotifications = _realtimeNotifications.sublist(0, 20);
    }
  }

  /// Mark a notification as read
  void markNotificationRead(int index) {
    if (index >= 0 && index < _realtimeNotifications.length) {
      _realtimeNotifications[index]['isRead'] = true;
      notifyListeners();
    }
  }

  /// Clear all notifications
  void clearNotifications() {
    _realtimeNotifications.clear();
    notifyListeners();
  }

  /// Get unread notification count
  int get unreadNotificationCount =>
      _realtimeNotifications.where((n) => n['isRead'] != true).length;

  /// ── Instant Booking ─────────────────────────────────
  Future<bool> createInstantBooking({
    required String serviceId,
    Map<String, dynamic>? customerLocation,
  }) async {
    _isLoading = true;
    _error = null;
    _instantStatus = 'searching';
    _confirmedProvider = null;
    notifyListeners();

    try {
      Map<String, dynamic>? locData = customerLocation;
      if (locData == null) {
        try {
          final pos = await LocationHelper.getCurrentLocation();
          if (pos != null) {
            locData = {
              'coordinates': [pos.longitude, pos.latitude],
              'address': 'Current Location',
            };
          }
        } catch (_) {}
      }

      _instantBooking = await _bookingApi.createInstantBooking(
        serviceId: serviceId,
        customerLocation: locData,
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

  /// Reset live tracking state
  void resetTracking() {
    _isTracking = false;
    _workerCoordinates = null;
    _lastLocationTimestamp = null;
    _trackingBookingId = null;
    notifyListeners();
  }

  /// Start live tracking manually for an active booking
  void startTrackingBooking(Booking booking) {
    _isTracking = true;
    _trackingBookingId = booking.id;
    if (booking.workerLocationCoordinates != null) {
      _workerCoordinates = booking.workerLocationCoordinates;
      _lastLocationTimestamp = DateTime.now().millisecondsSinceEpoch;
    } else {
      _workerCoordinates = null;
      _lastLocationTimestamp = null;
    }
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

  /// Create a new booking from match result
  Future<bool> createBooking({Map<String, dynamic>? customerLocation}) async {
    if (_matchResult == null) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic>? locData = customerLocation;
      if (locData == null) {
        try {
          final pos = await LocationHelper.getCurrentLocation();
          if (pos != null) {
            locData = {
              'coordinates': [pos.longitude, pos.latitude],
              'address': 'Current Location',
            };
          }
        } catch (_) {}
      }

      final booking = await _bookingApi.createBooking(
        providerId: _matchResult!.provider.id,
        serviceId: _matchResult!.service.id,
        date: _matchResult!.date,
        slot: _matchResult!.slot,
        price: _matchResult!.price,
        customerLocation: locData,
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
    Map<String, dynamic>? customerLocation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic>? locData = customerLocation;
      if (locData == null) {
        try {
          final pos = await LocationHelper.getCurrentLocation();
          if (pos != null) {
            locData = {
              'coordinates': [pos.longitude, pos.latitude],
              'address': 'Current Location',
            };
          }
        } catch (_) {}
      }

      final booking = await _bookingApi.createBooking(
        providerId: providerId,
        serviceId: serviceId,
        date: date,
        slot: slot,
        price: price,
        customerLocation: locData,
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

  /// Cancel a requested/pending booking
  Future<bool> cancelBooking(String id, {String? cancellationReason}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final booking = await _bookingApi.cancelBooking(
        id,
        cancellationReason: cancellationReason,
      );

      _selectedBooking = booking;
      _bookings = _bookings
          .map((existing) => existing.id == booking.id ? booking : existing)
          .toList();

      if (_instantBooking?.id == booking.id) {
        _instantBooking = null;
        _instantStatus = 'idle';
        _confirmedProvider = null;
      }

      _successMessage = 'Booking cancelled successfully.';
      _isLoading = false;
      notifyListeners();
      fetchBookings();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
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
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _completedSub?.cancel();
    _connectionSub?.cancel();
    _trackingStartedSub?.cancel();
    _workerLocationSub?.cancel();
    _paidSub?.cancel();
    _socketService.dispose();
    super.dispose();
  }
}
