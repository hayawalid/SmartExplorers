// ============================================================================
// chat_screen.dart
// Dedicated real-time chat screen between provider and traveler
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'dart:ui';
import 'package:mobile_app/theme/app_theme.dart';
import 'package:mobile_app/services/session_store.dart';
import 'package:mobile_app/services/messaging_api_service.dart';  // <-- changed

class ChatScreen extends StatefulWidget {
  final String recipientId;
  final String recipientName;
  final String? bookingId;
  final String? serviceName;

  const ChatScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.bookingId,
    this.serviceName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final MessagingApiService _messagingService = MessagingApiService();

  List<_ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final myId = SessionStore.instance.userId ?? '';
      final data = await _messagingService.getMessages(
        widget.recipientId,
      );
      if (!mounted) return;
      setState(() {
        _messages = data
            .map(
              (m) => _ChatMessage(
                id: m['_id']?.toString() ?? '',
                senderId: m['sender_id']?.toString() ?? '',
                text: m['text']?.toString() ?? '',
                createdAt: m['created_at']?.toString() ?? '',
                isMe: m['sender_id']?.toString() == myId,
              ),
            )
            .toList();
        _loading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    final myId = SessionStore.instance.userId;
    if (myId == null) return;

    final optimistic = _ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: myId,
      text: text,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      isMe: true,
    );

    setState(() {
      _messages.add(optimistic);
      _messageController.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      await _messagingService.sendMessage(
        widget.recipientId,
        text,
        bookingId: widget.bookingId,
      );
    } catch (_) {
      // Message shows optimistically regardless
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _messagingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppDesign.eerieBlack.withOpacity(0.92)
            : Colors.white.withOpacity(0.92),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrow_left, color: text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            _Avatar(label: widget.recipientName, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipientName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: text,
                    ),
                  ),
                  if (widget.serviceName != null)
                    Text(
                      widget.serviceName!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppDesign.midGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Booking context banner
          if (widget.bookingId != null)
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppDesign.navSafety.withOpacity(0.12)
                        : AppDesign.navSafety.withOpacity(0.08),
                    border: Border(
                      bottom: BorderSide(
                        color: AppDesign.navSafety.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar_check,
                        size: 14,
                        color: AppDesign.navSafety,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Booking confirmed — ${widget.serviceName ?? 'Service'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppDesign.navSafety,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Messages list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : AppDesign.offWhite,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.08)
                                      : AppDesign.lightGrey,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.message_circle,
                                size: 28,
                                color: AppDesign.midGrey,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Start the conversation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Send a message to ${widget.recipientName}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppDesign.midGrey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final msg = _messages[i];
                          final showDate = i == 0 ||
                              _shouldShowDate(
                                _messages[i - 1].createdAt,
                                msg.createdAt,
                              );
                          return Column(
                            children: [
                              if (showDate) _DateDivider(iso: msg.createdAt),
                              _MessageBubble(
                                message: msg,
                                isDark: isDark,
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Input area
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppDesign.eerieBlack.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : AppDesign.lightGrey,
                    ),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  MediaQuery.of(context).viewInsets.bottom +
                      MediaQuery.of(context).padding.bottom +
                      10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.06)
                              : AppDesign.offWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppDesign.lightGrey,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          maxLines: 4,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          style: TextStyle(
                            fontSize: 14,
                            color: text,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle:
                                const TextStyle(color: AppDesign.midGrey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppDesign.electricCobalt,
                        ),
                        child: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                LucideIcons.send,
                                size: 18,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDate(String prev, String curr) {
    try {
      final a = DateTime.parse(prev).toLocal();
      final b = DateTime.parse(curr).toLocal();
      return a.day != b.day || a.month != b.month || a.year != b.year;
    } catch (_) {
      return false;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isDark});
  final _ChatMessage message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _Avatar(label: '?', size: 28),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  child: BackdropFilter(
                    filter: isMe
                        ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
                        : ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppDesign.electricCobalt
                            : isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.white,
                        border: isMe
                            ? null
                            : Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : AppDesign.lightGrey,
                              ),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: isMe
                              ? Colors.white
                              : isDark
                                  ? Colors.white
                                  : AppDesign.eerieBlack,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(message.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppDesign.midGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.iso});
  final String iso;

  @override
  Widget build(BuildContext context) {
    String label = 'Today';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        label = 'Today';
      } else if (diff.inDays == 1) {
        label = 'Yesterday';
      } else {
        label = '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppDesign.midGrey),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, this.size = 40});
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppDesign.navConcierge,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String createdAt;
  final bool isMe;

  const _ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isMe,
  });
}