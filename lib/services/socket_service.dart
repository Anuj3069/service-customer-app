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
  String? _activeSupportTicketId;
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
  final _chatMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingPaidController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _supportMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _supportStatusController =
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
  Stream<Map<String, dynamic>> get onChatMessage =>
      _chatMessageController.stream;
  Stream<Map<String, dynamic>> get onBookingPaid =>
      _bookingPaidController.stream;
  Stream<Map<String, dynamic>> get onSupportMessage =>
      _supportMessageController.stream;
  Stream<Map<String, dynamic>> get onSupportStatusChanged =>
      _supportStatusController.stream;
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
      if (kDebugMode) debugPrint('[Socket] ✅ Connected: ${_socket!.id}');
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);

      // CRITICAL: Register user → backend stores in Redis HASH
      _socket!.emit('register', {'userId': userId});
      if (kDebugMode) {
        debugPrint('[Socket] 📡 Registered userId: $userId (Redis-backed)');
      }

      // Room membership doesn't survive a reconnect (new socket.id on the
      // server), so re-join any support ticket room the UI had joined —
      // otherwise support-chat messages silently stop arriving until the
      // screen is manually reopened.
      if (_activeSupportTicketId != null) {
        _socket!.emit('join-support', {'ticketId': _activeSupportTicketId});
      }
    });

    _socket!.onDisconnect((_) {
      if (kDebugMode) {
        debugPrint('[Socket] 🔌 Disconnected');
      }
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onReconnect((_) {
      if (kDebugMode) {
        debugPrint('[Socket] 🔄 Reconnected');
      }
      _reconnectAttempts = 0;
      // Re-register on reconnect so Redis mapping is refreshed
      _socket!.emit('register', {'userId': userId});
    });

    _socket!.onReconnectAttempt((attempt) {
      _reconnectAttempts = attempt is int ? attempt : 0;
      if (kDebugMode) {
        debugPrint('[Socket] 🔄 Reconnect attempt: $_reconnectAttempts');
      }
    });

    _socket!.onReconnectFailed((_) {
      if (kDebugMode) {
        debugPrint(
          '[Socket] ❌ Reconnection failed after $_maxReconnectAttempts attempts',
        );
      }
    });

    _socket!.onConnectError((err) {
      if (kDebugMode) {
        debugPrint('[Socket] ❌ Connect error: $err');
      }
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onError((err) {
      if (kDebugMode) {
        debugPrint('[Socket] ❌ Socket error: $err');
      }
    });

    // ── Booking events (routed from Redis Pub/Sub → Socket.IO) ──

    // Instant booking confirmed by a worker
    _socket!.on('booking-confirmed', (data) {
      if (kDebugMode) debugPrint('[Socket] 🎉 booking-confirmed: $data');
      _addToController(_bookingConfirmedController, data);
    });

    // Booking expired (Redis TTL keyspace notification)
    _socket!.on('booking-expired', (data) {
      if (kDebugMode) debugPrint('[Socket] ⏰ booking-expired: $data');
      _addToController(_bookingExpiredController, data);
    });

    // Scheduled booking accepted by worker
    _socket!.on('booking-accepted', (data) {
      if (kDebugMode) debugPrint('[Socket] ✅ booking-accepted: $data');
      _addToController(_bookingAcceptedController, data);
    });

    // Scheduled booking rejected by worker
    _socket!.on('booking-rejected', (data) {
      if (kDebugMode) debugPrint('[Socket] ❌ booking-rejected: $data');
      _addToController(_bookingRejectedController, data);
    });

    // Booking completed by worker
    _socket!.on('booking-completed', (data) {
      if (kDebugMode) debugPrint('[Socket] 🎉 booking-completed: $data');
      _addToController(_bookingCompletedController, data);
    });

    // ── Live Tracking events ──

    // Worker has started driving to customer
    _socket!.on('tracking-started', (data) {
      if (kDebugMode) debugPrint('[Socket] 📍 tracking-started: $data');
      _addToController(_trackingStartedController, data);
    });

    // Worker's live GPS location update
    _socket!.on('worker-location', (data) {
      if (kDebugMode) debugPrint('[Socket] 🗺️ worker-location: $data');
      _addToController(_workerLocationController, data);
    });

    _socket!.on('chat-message', (data) {
      if (kDebugMode) debugPrint('[Socket] chat-message: $data');
      _addToController(_chatMessageController, data);
    });

    _socket!.on('booking-paid', (data) {
      if (kDebugMode) debugPrint('[Socket] 💳 booking-paid: $data');
      _addToController(_bookingPaidController, data);
    });

    _socket!.on('support-message', (data) {
      if (kDebugMode) debugPrint('[Socket] 🎫 support-message: $data');
      _addToController(_supportMessageController, data);
    });

    _socket!.on('support-status-changed', (data) {
      if (kDebugMode) debugPrint('[Socket] 🎫 support-status-changed: $data');
      _addToController(_supportStatusController, data);
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

  void joinSupportRoom(String ticketId) {
    _activeSupportTicketId = ticketId;
    _socket?.emit('join-support', {'ticketId': ticketId});
  }

  void leaveSupportRoom(String ticketId) {
    if (_activeSupportTicketId == ticketId) _activeSupportTicketId = null;
    _socket?.emit('leave-support', {'ticketId': ticketId});
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
    _chatMessageController.close();
    _bookingPaidController.close();
    _supportMessageController.close();
    _supportStatusController.close();
    _connectionStateController.close();
  }
}
