import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../widgets/smart_explorers_logo.dart';
import '../services/chat_api_service.dart';
import '../models/chat_models.dart' as models;

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({Key? key}) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatApiService _chatService = ChatApiService();
  String? _conversationId;
  bool _isLoading = false;
  bool _isConnected = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hello! 👋 I'm your AI travel assistant for Egypt. I can help you with:\n\n• Planning your itinerary\n• Finding verified guides\n• Emergency assistance\n• Local recommendations\n• Translation help\n\nHow can I assist you today?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final isConnected = await _chatService.testConnection();
    setState(() {
      _isConnected = isConnected;
    });

    if (!isConnected) {
      _showErrorSnackBar('Unable to connect to server. Using offline mode.');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;
    });

    try {
      // Call the real API
      final response = await _chatService.sendMessage(
        message: userMessage,
        conversationId: _conversationId,
        userContext: {'first_time_egypt': true, 'traveling_alone': false},
      );

      // Store conversation ID for context
      _conversationId = response.conversationId;

      setState(() {
        _messages.add(
          ChatMessage(
            text: response.message,
            isUser: false,
            timestamp: response.timestamp,
            suggestions: response.suggestions,
          ),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            text:
                "Sorry, I'm having trouble connecting to the server. Please check your connection and try again.\n\nError: ${e.toString()}",
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ),
        );
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _useSuggestion(String suggestion) {
    _messageController.text = suggestion;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final secondaryTextColor =
        isDark ? Colors.white70 : const Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(textColor, secondaryTextColor, isDark),

            // Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingIndicator(isDark);
                  }
                  return _buildMessageBubble(
                    _messages[index],
                    isDark,
                    cardColor,
                    textColor,
                  );
                },
              ),
            ),

            // Input
            _buildInputArea(isDark, cardColor, textColor, secondaryTextColor),

            // Bottom padding for nav bar
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI is thinking...',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color secondaryTextColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const SmartExplorersLogo(size: LogoSize.tiny, showText: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online • 24/7 Support',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textColor.withOpacity(0.1),
            ),
            child: Icon(CupertinoIcons.ellipsis, color: secondaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment:
          message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment:
              message.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient:
                  message.isUser
                      ? const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      )
                      : null,
              color:
                  message.isUser
                      ? null
                      : (message.isError ?? false)
                      ? Colors.red.withOpacity(0.1)
                      : cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    (message.isError ?? false)
                        ? Colors.red.withOpacity(0.5)
                        : isDark
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFFE5E5EA),
                width: 1,
              ),
              boxShadow:
                  !isDark && !message.isUser
                      ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                      : null,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 16,
                color:
                    message.isUser
                        ? Colors.white
                        : (message.isError ?? false)
                        ? Colors.red
                        : textColor.withOpacity(0.9),
                fontFamily: 'SF Pro Text',
                height: 1.5,
              ),
            ),
          ),
        ),
        // Show suggestions if available
        if (!message.isUser &&
            message.suggestions != null &&
            message.suggestions!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  message.suggestions!
                      .map(
                        (suggestion) =>
                            _buildSuggestionChip(suggestion, isDark),
                      )
                      .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion, bool isDark) {
    return GestureDetector(
      onTap: () => _useSuggestion(suggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : const Color(0xFF8E8E93),
            fontFamily: 'SF Pro Text',
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color:
                isDark
                    ? Colors.white.withOpacity(0.2)
                    : const Color(0xFFE5E5EA),
            width: 1,
          ),
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDark
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFFF2F2F7),
              ),
              child: Icon(
                CupertinoIcons.plus,
                color: secondaryTextColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontFamily: 'SF Pro Text',
                ),
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(
                    color: secondaryTextColor,
                    fontFamily: 'SF Pro Text',
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.arrow_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? suggestions;
  final bool? isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions,
    this.isError,
  });
}
