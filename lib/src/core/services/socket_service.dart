import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:company_admin/src/core/constants/api_constants.dart';

/// Socket service for real-time updates in admin app
class AdminSocketService {
  static final AdminSocketService _instance = AdminSocketService._internal();
  io.Socket? _socket;
  bool _isInitialized = false;
  bool _hasJoinedSupportRoom = false;

  factory AdminSocketService() => _instance;
  AdminSocketService._internal();

  // Support messages stream - broadcast so multiple listeners can subscribe
  final _supportMessagesController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get supportMessages =>
      _supportMessagesController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void initSocket() {
    if (_isInitialized && _socket != null) return;

    // Extract base URL (remove /api)
    String baseUrl = ApiConstants.baseUrl;
    if (baseUrl.endsWith('/api')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 4);
    } else if (baseUrl.endsWith('/api/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 5);
    }

    debugPrint('🔌 Initializing socket with URL: $baseUrl');

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // Force websocket
          .setExtraHeaders({'x-app-id': 'Admin App'}) // Identifier for Analytics
          .disableAutoConnect() // Don't connect until we're ready
          .setReconnectionAttempts(5)
          .setReconnectionDelay(5000)
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('✅ Admin Socket Connected: ${_socket!.id}');
      _isInitialized = true;
      // Join support admin room to receive all support messages
      _joinSupportAdminRoom();
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ Admin Socket Disconnected');
      _hasJoinedSupportRoom = false;
    });

    _socket!.onConnectError(
      (err) => debugPrint('⚠️ Socket connection error: $err'),
    );
    _socket!.onError((err) => debugPrint('💥 Socket error: $err'));

    // Listen for support messages - only add listener once
    _socket!.on('new_support_message', (data) {
      debugPrint('📬 New support message received: $data');
      if (data != null && data is Map<String, dynamic>) {
        _supportMessagesController.add(data);
      }
    });
  }

  void _joinSupportAdminRoom() {
    if (_hasJoinedSupportRoom) return;

    if (_socket?.connected == true) {
      debugPrint('👨‍💼 Joining support-admin room');
      _socket!.emit('join-support-admin');
      _hasJoinedSupportRoom = true;
    }
  }

  /// Ensure socket is connected and joined
  void ensureConnected() {
    if (_socket == null) {
      initSocket();
    } else if (!_socket!.connected) {
      _socket!.connect();
    } else if (!_hasJoinedSupportRoom) {
      _joinSupportAdminRoom();
    }
  }

  void dispose() {
    _supportMessagesController.close();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isInitialized = false;
    _hasJoinedSupportRoom = false;
  }
}
