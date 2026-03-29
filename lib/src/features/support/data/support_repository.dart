import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:company_admin/src/core/constants/api_constants.dart';
import 'package:company_admin/src/core/network/api_client.dart';

/// Model for support message
class SupportMessage {
  final String sender;
  final String text;
  final DateTime timestamp;

  SupportMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      sender: json['sender'] ?? 'user',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// Model for support ticket
class SupportTicket {
  final String id;
  final String userId;
  final String userName;
  final String? userPhone;
  final String status;
  final List<SupportMessage> messages;
  final DateTime lastMessageAt;
  final DateTime createdAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    required this.status,
    required this.messages,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Customer',
      userPhone: json['userPhone'],
      status: json['status'] ?? 'open',
      messages: (json['messages'] as List? ?? [])
          .map((m) => SupportMessage.fromJson(m))
          .toList(),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Get last message preview
  String get lastMessagePreview {
    if (messages.isEmpty) return 'No messages';
    return messages.last.text.length > 50
        ? '${messages.last.text.substring(0, 50)}...'
        : messages.last.text;
  }

  /// Check if has unread (last message from user)
  bool get hasUnread {
    if (messages.isEmpty) return false;
    return messages.last.sender == 'user';
  }
}

/// Repository for support operations
class SupportRepository {
  final ApiClient _apiClient = ApiClient();

  /// Fetch all support tickets
  Future<List<SupportTicket>> getAllTickets() async {
    final response = await _apiClient.get(ApiConstants.allSupportTickets);
    final List<dynamic> data = response is List ? response : [];
    return data.map((json) => SupportTicket.fromJson(json)).toList();
  }

  /// Get single ticket by ID
  Future<SupportTicket> getTicketById(String ticketId) async {
    final response = await _apiClient.get(
      ApiConstants.supportTicketById(ticketId),
    );
    return SupportTicket.fromJson(response);
  }

  /// Send reply to ticket
  Future<void> sendReply({
    required String ticketId,
    required String message,
  }) async {
    await _apiClient.post(
      ApiConstants.sendSupportReply,
      body: {'ticketId': ticketId, 'message': message, 'sender': 'admin'},
    );
  }

  /// Close ticket
  Future<void> closeTicket(String ticketId) async {
    await _apiClient.put(ApiConstants.closeSupportTicket(ticketId));
  }
}

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository();
});

/// Provider for all tickets
final supportTicketsProvider = FutureProvider.autoDispose<List<SupportTicket>>((
  ref,
) async {
  return ref.read(supportRepositoryProvider).getAllTickets();
});
