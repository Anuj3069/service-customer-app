import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Manages Socket.IO connection for real-time instant booking events.
/// Customer listens for: booking-confirmed, booking-expired
class SocketService {
  static const String _serverUrl = 'http://10.0.2.2:3000';

  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // Stream controllers for events
  final _bookingConfirmedController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _bookingExpiredController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onBookingConfirmed =>
      _bookingConfirmedController.stream;
  Stream<Map<String, dynamic>> get onBookingExpired =>
      _bookingExpiredController.stream;

  /// Connect to the socket server and register the user
  void connect(String userId) {
    if (_socket != null) {
      _socket!.dispose();
    }

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[Socket] Connected: ${_socket!.id}');
      _isConnected = true;

      // CRITICAL: Register user so backend maps socket to userId
      _socket!.emit('register', {'userId': userId});
      debugPrint('[Socket] Registered userId: $userId');
    });

    _socket!.on('booking-confirmed', (data) {
      debugPrint('[Socket] booking-confirmed: $data');
      if (data is Map<String, dynamic>) {
        _bookingConfirmedController.add(data);
      } else if (data is Map) {
        _bookingConfirmedController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('booking-expired', (data) {
      debugPrint('[Socket] booking-expired: $data');
      if (data is Map<String, dynamic>) {
        _bookingExpiredController.add(data);
      } else if (data is Map) {
        _bookingExpiredController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('[Socket] Disconnected');
      _isConnected = false;
    });

    _socket!.onConnectError((err) {
      debugPrint('[Socket] Connect error: $err');
      _isConnected = false;
    });

    _socket!.connect();
  }

  /// Disconnect from socket server
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _bookingConfirmedController.close();
    _bookingExpiredController.close();
  }
}
