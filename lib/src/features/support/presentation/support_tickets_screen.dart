import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:company_admin/src/features/support/data/support_repository.dart';
import 'package:company_admin/src/core/services/socket_service.dart';
import 'package:intl/intl.dart';

class SupportTicketsScreen extends ConsumerStatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  ConsumerState<SupportTicketsScreen> createState() =>
      _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends ConsumerState<SupportTicketsScreen> {
  StreamSubscription? _socketSubscription;

  @override
  void initState() {
    super.initState();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    // Ensure socket is connected
    AdminSocketService().ensureConnected();

    // Listen for real-time support messages (from users)
    _socketSubscription = AdminSocketService().supportMessages.listen((data) {
      final message = data['message'];
      final sender = message?['sender'];

      // Only refresh on USER messages (admin messages we already handled locally)
      if (sender == 'user') {
        // print('📬 New user message, refreshing tickets list');
        ref.invalidate(supportTicketsProvider);
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Tickets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(supportTicketsProvider),
          ),
        ],
      ),
      body: ticketsAsync.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No support tickets yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'When users send help requests, they\'ll appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(supportTicketsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                return _buildTicketCard(context, ticket);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(supportTicketsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, SupportTicket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: ticket.status == 'open'
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.grey.shade200,
              child: Text(
                ticket.userName.isNotEmpty
                    ? ticket.userName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: ticket.status == 'open'
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (ticket.hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                ticket.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ticket.status == 'open'
                    ? Colors.green.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                ticket.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ticket.status == 'open' ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              ticket.lastMessagePreview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ticket.hasUnread ? Colors.black87 : Colors.grey,
                fontWeight: ticket.hasUnread
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(ticket.lastMessageAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => context.go('/support/${ticket.id}'),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }
}
