import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Manages Socket.IO connection for real-time booking events.
///
/// Listens for all Redis Pub/Sub events routed through the backend:
///   - booking-confirmed  → Instant booking accepted by a worker
///   - booking-expired    → Booking expired (Redis TTL keyspace notification)
///   - booking-accepted   → Scheduled booking accepted by worker
///   - booking-rejected   → Scheduled booking rejected by worker
///   - booking-completed  → Booking marked complete by worker
class SocketService {
  static const String _serverUrl = 'https://service-app-rduc.onrender.com';

  io.Socket? _socket;
  bool _isConnected = false;
  String? _userId;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  bool get isConnected => _isConnected;
  String? get userId => _userId;

  // ── Stream Controllers (broadcast so multiple listeners work) ──
  final _bookingConfirmedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingExpiredController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingAcceptedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingRejectedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingCompletedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _trackingStartedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _workerLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // ── Public Streams ──
  Stream<Map<String, dynamic>> get onBookingConfirmed =>
      _bookingConfirmedController.stream;
  Stream<Map<String, dynamic>> get onBookingExpired =>
      _bookingExpiredController.stream;
  Stream<Map<String, dynamic>> get onBookingAccepted =>
      _bookingAcceptedController.stream;
  Stream<Map<String, dynamic>> get onBookingRejected =>
      _bookingRejectedController.stream;
  Stream<Map<String, dynamic>> get onBookingCompleted =>
      _bookingCompletedController.stream;
  Stream<Map<String, dynamic>> get onTrackingStarted =>
      _trackingStartedController.stream;
  Stream<Map<String, dynamic>> get onWorkerLocation =>
      _workerLocationController.stream;
  Stream<bool> get onConnectionStateChanged =>
      _connectionStateController.stream;

  /// Connect to the socket server and register the user.
  /// The backend maps this socket to userId in Redis HASH (online_users).
  void connect(String userId) {
    _userId = userId;
    _reconnectAttempts = 0;

    if (_socket != null) {
      _socket!.dispose();
    }

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    // ── Connection lifecycle ──
    _socket!.onConnect((_) {
      debugPrint('[Socket] ✅ Connected: ${_socket!.id}');
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);

      // CRITICAL: Register user → backend stores in Redis HASH
      _socket!.emit('register', {'userId': userId});
      debugPrint('[Socket] 📡 Registered userId: $userId (Redis-backed)');
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] 🔌 Disconnected');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onReconnect((_) {
      debugPrint('[Socket] 🔄 Reconnected');
      _reconnectAttempts = 0;
      // Re-register on reconnect so Redis mapping is refreshed
      _socket!.emit('register', {'userId': userId});
    });

    _socket!.onReconnectAttempt((attempt) {
      _reconnectAttempts = attempt is int ? attempt : 0;
      debugPrint('[Socket] 🔄 Reconnect attempt: $_reconnectAttempts');
    });

    _socket!.onReconnectFailed((_) {
      debugPrint('[Socket] ❌ Reconnection failed after $_maxReconnectAttempts attempts');
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] ❌ Connect error: $err');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onError((err) {
      debugPrint('[Socket] ❌ Socket error: $err');
    });

    // ── Booking events (routed from Redis Pub/Sub → Socket.IO) ──

    // Instant booking confirmed by a worker
    _socket!.on('booking-confirmed', (data) {
      debugPrint('[Socket] 🎉 booking-confirmed: $data');
      _addToController(_bookingConfirmedController, data);
    });

    // Booking expired (Redis TTL keyspace notification)
    _socket!.on('booking-expired', (data) {
      debugPrint('[Socket] ⏰ booking-expired: $data');
      _addToController(_bookingExpiredController, data);
    });

    // Scheduled booking accepted by worker
    _socket!.on('booking-accepted', (data) {
      debugPrint('[Socket] ✅ booking-accepted: $data');
      _addToController(_bookingAcceptedController, data);
    });

    // Scheduled booking rejected by worker
    _socket!.on('booking-rejected', (data) {
      debugPrint('[Socket] ❌ booking-rejected: $data');
      _addToController(_bookingRejectedController, data);
    });

    // Booking completed by worker
    _socket!.on('booking-completed', (data) {
      debugPrint('[Socket] 🎉 booking-completed: $data');
      _addToController(_bookingCompletedController, data);
    });

    // ── Live Tracking events ──

    // Worker has started driving to customer
    _socket!.on('tracking-started', (data) {
      debugPrint('[Socket] 📍 tracking-started: $data');
      _addToController(_trackingStartedController, data);
    });

    // Worker's live GPS location update
    _socket!.on('worker-location', (data) {
      debugPrint('[Socket] 🗺️ worker-location: $data');
      _addToController(_workerLocationController, data);
    });

    _socket!.connect();
  }

  /// Helper to safely add data to a stream controller
  void _addToController(
    StreamController<Map<String, dynamic>> controller,
    dynamic data,
  ) {
    if (controller.isClosed) return;
    if (data is Map<String, dynamic>) {
      controller.add(data);
    } else if (data is Map) {
      controller.add(Map<String, dynamic>.from(data));
    }
  }

  /// Disconnect from socket server
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _userId = null;
    _connectionStateController.add(false);
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _bookingConfirmedController.close();
    _bookingExpiredController.close();
    _bookingAcceptedController.close();
    _bookingRejectedController.close();
    _bookingCompletedController.close();
    _trackingStartedController.close();
    _workerLocationController.close();
    _connectionStateController.close();
  }
}
