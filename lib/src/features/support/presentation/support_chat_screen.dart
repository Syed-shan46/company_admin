import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:company_admin/src/features/support/data/support_repository.dart';
import 'package:company_admin/src/core/services/socket_service.dart';
import 'package:company_admin/src/core/widgets/app_snackbar.dart';
import 'package:intl/intl.dart';

/// Provider to fetch a specific ticket
final ticketByIdProvider = FutureProvider.autoDispose
    .family<SupportTicket, String>((ref, ticketId) async {
      return ref.read(supportRepositoryProvider).getTicketById(ticketId);
    });

class SupportChatScreen extends ConsumerStatefulWidget {
  final String ticketId;

  const SupportChatScreen({super.key, required this.ticketId});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  StreamSubscription? _socketSubscription;
  // bool _justSentMessage = false; // Flag to prevent double refresh

  @override
  void initState() {
    super.initState();
    _setupSocketListener();
  }

  void _setupSocketListener() {
    // Listen for real-time messages for this ticket (from user side)
    _socketSubscription = AdminSocketService().supportMessages.listen((data) {
      final ticketId = data['ticketId']?.toString();
      final message = data['message'];
      final sender = message?['sender'];

      // Only refresh if this is a USER message (not our own admin message)
      // and it's for this ticket
      if (ticketId == widget.ticketId && sender == 'user') {
        debugPrint('💬 New user message received, refreshing chat');
        ref.invalidate(ticketByIdProvider(widget.ticketId));
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    // _justSentMessage = true;

    try {
      await ref
          .read(supportRepositoryProvider)
          .sendReply(ticketId: widget.ticketId, message: text);
      _messageController.clear();

      // Refresh ticket data
      ref.invalidate(ticketByIdProvider(widget.ticketId));
      ref.invalidate(supportTicketsProvider);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to send: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        // Reset flag after a delay
        Future.delayed(const Duration(seconds: 1), () {
          // _justSentMessage = false;
        });
      }
    }
  }

  Future<void> _closeTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close Ticket?'),
        content: const Text('This will mark the ticket as resolved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(supportRepositoryProvider).closeTicket(widget.ticketId);
        ref.invalidate(ticketByIdProvider(widget.ticketId));
        ref.invalidate(supportTicketsProvider);
        if (mounted) {
          AppSnackbar.success(context, 'Ticket closed successfully');
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, 'Failed to close: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketByIdProvider(widget.ticketId));

    return Scaffold(
      appBar: AppBar(
        title: ticketAsync.when(
          data: (t) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.userName, style: const TextStyle(fontSize: 16)),
              Text(
                t.userPhone ?? 'No phone',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Support Chat'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(ticketByIdProvider(widget.ticketId)),
          ),
          ticketAsync.when(
            data: (t) => t.status == 'open'
                ? IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Close Ticket',
                    onPressed: _closeTicket,
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: ticketAsync.when(
        data: (ticket) => Column(
          children: [
            // Status banner
            if (ticket.status == 'closed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: const Text(
                  'This ticket is closed',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: ticket.messages.length,
                itemBuilder: (context, index) {
                  final msg = ticket.messages[index];
                  final isAdmin = msg.sender == 'admin';

                  return Align(
                    alignment: isAdmin
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isAdmin
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottomRight: isAdmin
                              ? Radius.zero
                              : const Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: isAdmin ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('h:mm a').format(msg.timestamp),
                            style: TextStyle(
                              fontSize: 10,
                              color: isAdmin ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input
            if (ticket.status == 'open')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendReply(),
                        enabled: !_isSending,
                        decoration: InputDecoration(
                          hintText: 'Type your reply...',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _sendReply,
                            ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
                onPressed: () =>
                    ref.invalidate(ticketByIdProvider(widget.ticketId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
