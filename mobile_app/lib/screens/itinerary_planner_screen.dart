import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'itinerary_detail_screen.dart';

/// Chat-to-Plan Itinerary Planner with WCAG 2.1 AA compliance
/// Features: AI chat, frosted glass loading, Accept/Deny cards, Hero animations
class ItineraryPlannerScreen extends StatefulWidget {
  const ItineraryPlannerScreen({Key? key}) : super(key: key);

  @override
  State<ItineraryPlannerScreen> createState() => _ItineraryPlannerScreenState();
}

class _ItineraryPlannerScreenState extends State<ItineraryPlannerScreen>
    with TickerProviderStateMixin {
  // State management
  ItineraryPlannerPhase _currentPhase = ItineraryPlannerPhase.chat;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Animation controllers
  late AnimationController _loadingAnimController;
  late AnimationController _cardRevealController;
  late Animation<double> _pulseAnimation;

  // Chat messages
  final List<ChatMessage> _messages = [];

  // User preferences (collected from chat)
  String? _selectedGender;
  List<String> _selectedAccessibilityNeeds = [];
  List<String> _selectedInterests = [];

  // Generated itinerary
  List<ItineraryItem> _generatedItinerary = [];
  int _currentRevealIndex = 0;

  // Quick preference options
  final List<String> _genderOptions = [
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];
  final List<String> _accessibilityOptions = [
    'Wheelchair Access',
    'Visual Assistance',
    'Hearing Assistance',
    'Mobility Support',
    'Sensory Friendly',
    'No Special Needs',
  ];
  final List<String> _interestOptions = [
    'Ancient History',
    'Adventure',
    'Relaxation',
    'Food & Culinary',
    'Photography',
    'Cultural Experiences',
    'Nature & Wildlife',
    'Shopping',
  ];

  @override
  void initState() {
    super.initState();
    _loadingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _cardRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _loadingAnimController, curve: Curves.easeInOut),
    );

    // Initial greeting message
    _addBotMessage(
      "Hello! 🌍 I'm your SmartExplorers AI assistant. Let me help you plan the perfect Egyptian adventure!\n\n"
      "First, I'll ask a few questions to personalize your experience.",
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _askGenderPreference();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _loadingAnimController.dispose();
    _cardRevealController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text, {List<QuickReply>? quickReplies}) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          quickReplies: quickReplies,
        ),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _askGenderPreference() {
    _addBotMessage(
      "To ensure your safety and comfort, please tell me how you identify:",
      quickReplies:
          _genderOptions.map((g) => QuickReply(label: g, value: g)).toList(),
    );
  }

  void _handleGenderSelection(String gender) {
    HapticFeedback.selectionClick();
    _selectedGender = gender;
    _addUserMessage(gender);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _askAccessibilityNeeds();
    });
  }

  void _askAccessibilityNeeds() {
    _addBotMessage(
      "Do you have any accessibility needs? This helps me recommend suitable activities and transportation.\n\n"
      "Select all that apply:",
      quickReplies:
          _accessibilityOptions
              .map((a) => QuickReply(label: a, value: a, isMultiSelect: true))
              .toList(),
    );
  }

  void _handleAccessibilitySelection(List<String> needs) {
    HapticFeedback.selectionClick();
    _selectedAccessibilityNeeds = needs;
    _addUserMessage(needs.isEmpty ? 'No Special Needs' : needs.join(', '));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _askInterests();
    });
  }

  void _askInterests() {
    _addBotMessage(
      "What interests you most about Egypt? 🏛️\n\n"
      "Pick your top 3 interests:",
      quickReplies:
          _interestOptions
              .map((i) => QuickReply(label: i, value: i, isMultiSelect: true))
              .toList(),
    );
  }

  void _handleInterestsSelection(List<String> interests) {
    HapticFeedback.selectionClick();
    _selectedInterests = interests;
    _addUserMessage(interests.join(', '));

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _startItineraryGeneration();
    });
  }

  void _startItineraryGeneration() {
    _addBotMessage(
      "Perfect! ✨ Based on your preferences, I'm now creating a personalized 3-day itinerary for you...",
    );

    setState(() => _currentPhase = ItineraryPlannerPhase.generating);

    // Simulate AI generation
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _generateItinerary();
        setState(() => _currentPhase = ItineraryPlannerPhase.review);
        _revealCardsSequentially();
      }
    });
  }

  void _generateItinerary() {
    // Generate sample itinerary based on user preferences
    _generatedItinerary = [
      ItineraryItem(
        id: '1',
        day: 1,
        title: 'Pyramids of Giza',
        time: '6:00 AM - 12:00 PM',
        description:
            'Start your Egyptian adventure at the ancient Pyramids of Giza. '
            'Experience the majesty of the Great Pyramid, Sphinx, and panoramic views.',
        imageEmoji: '🏛️',
        location: 'Giza Plateau',
        accessibilityRating: 3,
        accessibilityNotes:
            'Wheelchair accessible paths available, ramps at main areas',
        tags: ['Ancient History', 'Photography'],
        estimatedCost: '\$25',
        altText:
            'The Great Pyramids of Giza at sunrise with the Sphinx in foreground',
      ),
      ItineraryItem(
        id: '2',
        day: 1,
        title: 'Egyptian Museum',
        time: '2:00 PM - 5:00 PM',
        description:
            'Explore the world\'s largest collection of ancient Egyptian artifacts, '
            'including King Tutankhamun\'s golden mask.',
        imageEmoji: '🏺',
        location: 'Tahrir Square, Cairo',
        accessibilityRating: 4,
        accessibilityNotes: 'Full wheelchair access, audio guides available',
        tags: ['Ancient History', 'Cultural Experiences'],
        estimatedCost: '\$15',
        altText:
            'Interior of the Egyptian Museum showing ancient artifacts and statues',
      ),
      ItineraryItem(
        id: '3',
        day: 1,
        title: 'Khan el-Khalili Bazaar',
        time: '6:00 PM - 9:00 PM',
        description:
            'Experience the vibrant atmosphere of Cairo\'s famous medieval marketplace. '
            'Perfect for souvenirs and authentic Egyptian cuisine.',
        imageEmoji: '🛍️',
        location: 'Islamic Cairo',
        accessibilityRating: 2,
        accessibilityNotes: 'Narrow pathways, limited wheelchair access',
        tags: ['Shopping', 'Food & Culinary'],
        estimatedCost: '\$30',
        altText:
            'Colorful lanterns and spices at Khan el-Khalili market at night',
      ),
      ItineraryItem(
        id: '4',
        day: 2,
        title: 'Luxor Temple',
        time: '8:00 AM - 11:00 AM',
        description:
            'Marvel at the magnificent Luxor Temple, built primarily by Amenhotep III '
            'and Ramesses II over 3,000 years ago.',
        imageEmoji: '⚱️',
        location: 'Luxor',
        accessibilityRating: 3,
        accessibilityNotes:
            'Main pathways accessible, some areas have uneven ground',
        tags: ['Ancient History', 'Photography'],
        estimatedCost: '\$20',
        altText: 'Massive columns of Luxor Temple illuminated at golden hour',
      ),
      ItineraryItem(
        id: '5',
        day: 2,
        title: 'Valley of the Kings',
        time: '1:00 PM - 4:00 PM',
        description:
            'Descend into the ancient burial chambers of Egypt\'s pharaohs. '
            'Explore up to three tombs including Tutankhamun\'s.',
        imageEmoji: '👑',
        location: 'West Bank, Luxor',
        accessibilityRating: 2,
        accessibilityNotes:
            'Some tombs have steep descents, mobility assistance available',
        tags: ['Ancient History', 'Adventure'],
        estimatedCost: '\$25',
        altText:
            'Entrance to royal tomb in Valley of the Kings with hieroglyphic walls',
      ),
      ItineraryItem(
        id: '6',
        day: 3,
        title: 'Red Sea Snorkeling',
        time: '9:00 AM - 2:00 PM',
        description:
            'Dive into the crystal-clear waters of the Red Sea. '
            'Discover vibrant coral reefs and exotic marine life.',
        imageEmoji: '🐠',
        location: 'Hurghada',
        accessibilityRating: 2,
        accessibilityNotes: 'Adaptive equipment available upon request',
        tags: ['Adventure', 'Nature & Wildlife'],
        estimatedCost: '\$60',
        altText: 'Colorful fish and coral reef in the Red Sea',
      ),
    ];
  }

  void _revealCardsSequentially() {
    if (_currentRevealIndex < _generatedItinerary.length) {
      Future.delayed(Duration(milliseconds: 200 * _currentRevealIndex), () {
        if (mounted) {
          setState(() => _currentRevealIndex++);
          HapticFeedback.lightImpact();
        }
      });
      _currentRevealIndex++;
      _revealCardsSequentially();
    }
  }

  void _toggleItemAcceptance(String id, bool accepted) {
    HapticFeedback.mediumImpact();
    setState(() {
      final index = _generatedItinerary.indexWhere((item) => item.id == id);
      if (index != -1) {
        _generatedItinerary[index] = _generatedItinerary[index].copyWith(
          isAccepted: accepted,
        );
      }
    });
  }

  void _confirmItinerary() {
    HapticFeedback.heavyImpact();
    final acceptedItems =
        _generatedItinerary.where((i) => i.isAccepted).toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${acceptedItems.length} activities added to your itinerary!',
          style: const TextStyle(fontFamily: 'SF Pro Text'),
        ),
        backgroundColor: const Color(0xFF667eea),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    setState(() => _currentPhase = ItineraryPlannerPhase.confirmed);
  }

  void _regenerateItinerary() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentRevealIndex = 0;
      _currentPhase = ItineraryPlannerPhase.generating;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _currentPhase = ItineraryPlannerPhase.review);
        _revealCardsSequentially();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    // Auto-switch to dark mode for high contrast accessibility
    final effectiveIsDark = isDark || mediaQuery.highContrast;

    final backgroundColor =
        effectiveIsDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA);
    final cardColor = effectiveIsDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = effectiveIsDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtitleColor =
        effectiveIsDark ? Colors.white70 : const Color(0xFF6B7280);

    // SmartExplorers Blue for accepted items (WCAG AA compliant)
    const accentBlue = Color(0xFF667eea);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Main content based on phase
          SafeArea(
            bottom: false,
            child: _buildPhaseContent(
              effectiveIsDark,
              cardColor,
              textColor,
              subtitleColor,
              accentBlue,
            ),
          ),

          // Frosted glass loading overlay
          if (_currentPhase == ItineraryPlannerPhase.generating)
            _buildGeneratingOverlay(effectiveIsDark, textColor),
        ],
      ),
    );
  }

  Widget _buildPhaseContent(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color accentBlue,
  ) {
    switch (_currentPhase) {
      case ItineraryPlannerPhase.chat:
        return _buildChatInterface(isDark, cardColor, textColor, subtitleColor);
      case ItineraryPlannerPhase.generating:
      case ItineraryPlannerPhase.review:
      case ItineraryPlannerPhase.confirmed:
        return _buildItineraryView(
          isDark,
          cardColor,
          textColor,
          subtitleColor,
          accentBlue,
        );
    }
  }

  // ==================== CHAT INTERFACE ====================

  Widget _buildChatInterface(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Column(
      children: [
        // Header
        _buildHeader(textColor, subtitleColor, isDark),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: _messages.length,
            itemBuilder:
                (context, index) => _buildMessageBubble(
                  _messages[index],
                  isDark,
                  cardColor,
                  textColor,
                  subtitleColor,
                ),
          ),
        ),

        // Input area
        _buildInputArea(isDark, cardColor, textColor, subtitleColor),

        // Bottom padding for nav bar
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHeader(Color textColor, Color subtitleColor, bool isDark) {
    return Semantics(
      header: true,
      label: 'Itinerary Planner - AI Travel Assistant',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF764ba2), Color(0xFF667eea)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF764ba2).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🗺️', style: TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Itinerary Planner',
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
                        'AI Assistant • Ready to plan',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Reset conversation',
              child: GestureDetector(
                onTap: _resetConversation,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: textColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    CupertinoIcons.refresh,
                    color: subtitleColor,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetConversation() {
    HapticFeedback.mediumImpact();
    setState(() {
      _messages.clear();
      _selectedGender = null;
      _selectedAccessibilityNeeds.clear();
      _selectedInterests.clear();
      _generatedItinerary.clear();
      _currentRevealIndex = 0;
      _currentPhase = ItineraryPlannerPhase.chat;
    });

    _addBotMessage(
      "Let's start fresh! 🌍 I'm your SmartExplorers AI assistant. "
      "Ready to plan another adventure?",
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _askGenderPreference();
    });
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    final isUser = message.isUser;

    return Semantics(
      label:
          isUser
              ? 'Your message: ${message.text}'
              : 'AI assistant says: ${message.text}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF667eea) : cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 16,
                  color: isUser ? Colors.white : textColor,
                  fontFamily: 'SF Pro Text',
                  height: 1.4,
                ),
              ),
            ),

            // Quick replies for bot messages
            if (!isUser && message.quickReplies != null)
              _buildQuickReplies(message.quickReplies!, isDark, cardColor),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies(
    List<QuickReply> replies,
    bool isDark,
    Color cardColor,
  ) {
    final isMultiSelect = replies.any((r) => r.isMultiSelect);
    List<String> selectedValues = [];

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    replies.map((reply) {
                      final isSelected = selectedValues.contains(reply.value);

                      return Semantics(
                        button: true,
                        label:
                            '${reply.label}${isSelected ? ', selected' : ''}',
                        hint:
                            isMultiSelect
                                ? 'Tap to toggle selection'
                                : 'Tap to select this option',
                        child: GestureDetector(
                          onTap: () {
                            if (isMultiSelect) {
                              setLocalState(() {
                                if (isSelected) {
                                  selectedValues.remove(reply.value);
                                } else {
                                  if (reply.value == 'No Special Needs') {
                                    selectedValues.clear();
                                  } else {
                                    selectedValues.remove('No Special Needs');
                                  }
                                  if (selectedValues.length < 3 ||
                                      replies ==
                                          _accessibilityOptions
                                              .map(
                                                (a) => QuickReply(
                                                  label: a,
                                                  value: a,
                                                  isMultiSelect: true,
                                                ),
                                              )
                                              .toList()) {
                                    selectedValues.add(reply.value);
                                  }
                                }
                              });
                            } else {
                              _handleGenderSelection(reply.value);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFF667eea)
                                      : cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? const Color(0xFF667eea)
                                        : (isDark
                                            ? Colors.white.withOpacity(0.2)
                                            : const Color(0xFFE5E5EA)),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              reply.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white
                                            : const Color(0xFF1C1C1E)),
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),

              // Confirm button for multi-select
              if (isMultiSelect && selectedValues.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Semantics(
                    button: true,
                    label: 'Confirm selection',
                    child: GestureDetector(
                      onTap: () {
                        if (_selectedGender != null &&
                            _selectedAccessibilityNeeds.isEmpty) {
                          _handleAccessibilitySelection(selectedValues);
                        } else {
                          _handleInterestsSelection(selectedValues);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Continue →',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputArea(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              textField: true,
              label: 'Type your message',
              child: CupertinoTextField(
                controller: _messageController,
                placeholder: 'Type a message...',
                placeholderStyle: TextStyle(
                  color: subtitleColor,
                  fontFamily: 'SF Pro Text',
                ),
                style: TextStyle(color: textColor, fontFamily: 'SF Pro Text'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.1)
                          : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: 'Send message',
            child: GestureDetector(
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
                  CupertinoIcons.paperplane_fill,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    _addUserMessage(_messageController.text);
    _messageController.clear();
  }

  // ==================== GENERATING OVERLAY ====================

  Widget _buildGeneratingOverlay(bool isDark, Color textColor) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667eea).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('✨', style: TextStyle(fontSize: 50)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Semantics(
                liveRegion: true,
                label: 'Generating your personalized itinerary',
                child: Text(
                  'Creating Your\nPerfect Itinerary',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Analyzing your preferences...',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.7),
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ITINERARY VIEW ====================

  Widget _buildItineraryView(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color accentBlue,
  ) {
    // Group items by day
    final Map<int, List<ItineraryItem>> groupedByDay = {};
    for (final item in _generatedItinerary) {
      groupedByDay.putIfAbsent(item.day, () => []).add(item);
    }

    return Column(
      children: [
        // Header with action buttons
        _buildItineraryHeader(textColor, subtitleColor, isDark, accentBlue),

        // Instagram-style timeline
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groupedByDay.length,
            itemBuilder: (context, dayIndex) {
              final day = dayIndex + 1;
              final items = groupedByDay[day] ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day header
                  Semantics(
                    header: true,
                    label: 'Day $day activities',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Day $day',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: subtitleColor.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Activity cards for this day
                  ...items.asMap().entries.map((entry) {
                    final itemIndex = _generatedItinerary.indexOf(entry.value);
                    final shouldShow = itemIndex < _currentRevealIndex;

                    if (!shouldShow) return const SizedBox.shrink();

                    return _buildItineraryCard(
                      entry.value,
                      isDark,
                      cardColor,
                      textColor,
                      subtitleColor,
                      accentBlue,
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),

        // Bottom action bar
        if (_currentPhase == ItineraryPlannerPhase.review)
          _buildBottomActionBar(isDark, cardColor, textColor),

        // Bottom padding for nav bar
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildItineraryHeader(
    Color textColor,
    Color subtitleColor,
    bool isDark,
    Color accentBlue,
  ) {
    final acceptedCount = _generatedItinerary.where((i) => i.isAccepted).length;

    return Semantics(
      header: true,
      label: 'Your personalized itinerary, $acceptedCount activities accepted',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Itinerary',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$acceptedCount of ${_generatedItinerary.length} activities selected',
                    style: TextStyle(
                      fontSize: 14,
                      color: subtitleColor,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: 'Regenerate itinerary',
              hint: 'Tap to create a new itinerary',
              child: GestureDetector(
                onTap: _regenerateItinerary,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentBlue.withOpacity(0.2),
                  ),
                  child: Icon(
                    CupertinoIcons.refresh,
                    color: accentBlue,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItineraryCard(
    ItineraryItem item,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subtitleColor,
    Color accentBlue,
  ) {
    final isAccepted = item.isAccepted;
    final isConfirmed = _currentPhase == ItineraryPlannerPhase.confirmed;

    return Semantics(
      container: true,
      label: '${item.title}, ${item.time}, ${item.location}',
      hint:
          isConfirmed
              ? (isAccepted ? 'Accepted activity' : 'Declined activity')
              : 'Tap Accept to add, Deny to remove, or tap card for details',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          onTap: () => _openItemDetail(item),
          child: Hero(
            tag: 'itinerary_${item.id}',
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isAccepted
                            ? accentBlue
                            : (isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05)),
                    width: isAccepted ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isAccepted
                              ? accentBlue.withOpacity(0.2)
                              : Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image area with Accept/Deny buttons
                    Stack(
                      children: [
                        // Activity image
                        Semantics(
                          image: true,
                          label: item.altText,
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    isAccepted
                                        ? [
                                          accentBlue.withOpacity(0.3),
                                          const Color(
                                            0xFF764ba2,
                                          ).withOpacity(0.3),
                                        ]
                                        : [
                                          const Color(
                                            0xFF667eea,
                                          ).withOpacity(0.2),
                                          const Color(
                                            0xFFf5576c,
                                          ).withOpacity(0.2),
                                        ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                item.imageEmoji,
                                style: TextStyle(
                                  fontSize: 80,
                                  color:
                                      isAccepted
                                          ? Colors.white.withOpacity(0.9)
                                          : null,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Accept/Deny buttons (top right, 44x44 for accessibility)
                        if (!isConfirmed)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Row(
                              children: [
                                // Deny button
                                Semantics(
                                  button: true,
                                  label: 'Deny this activity',
                                  hint: 'Tap to remove from itinerary',
                                  child: GestureDetector(
                                    onTap:
                                        () => _toggleItemAcceptance(
                                          item.id,
                                          false,
                                        ),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            !isAccepted
                                                ? const Color(0xFFf5576c)
                                                : Colors.black.withOpacity(0.5),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.xmark,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Accept button
                                Semantics(
                                  button: true,
                                  label: 'Accept this activity',
                                  hint:
                                      'Tap to add to your permanent itinerary',
                                  child: GestureDetector(
                                    onTap:
                                        () => _toggleItemAcceptance(
                                          item.id,
                                          true,
                                        ),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            isAccepted
                                                ? const Color(0xFF4CAF50)
                                                : Colors.black.withOpacity(0.5),
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.checkmark,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Accepted badge
                        if (isAccepted)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: accentBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.checkmark_circle_fill,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Added',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'SF Pro Text',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Card content
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time
                          Text(
                            item.time,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentBlue,
                              fontFamily: 'SF Pro Text',
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Title
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Location
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.location_solid,
                                size: 14,
                                color: subtitleColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.location,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subtitleColor,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Description (truncated)
                          Text(
                            item.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.8),
                              fontFamily: 'SF Pro Text',
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tags and accessibility rating
                          Row(
                            children: [
                              // Tags
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children:
                                      item.tags.take(2).map((tag) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentBlue.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: accentBlue,
                                              fontFamily: 'SF Pro Text',
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ),

                              // Accessibility rating
                              Semantics(
                                label:
                                    'Accessibility rating: ${item.accessibilityRating} out of 5',
                                child: Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < item.accessibilityRating
                                          ? CupertinoIcons
                                              .person_crop_circle_fill
                                          : CupertinoIcons.person_crop_circle,
                                      size: 16,
                                      color:
                                          index < item.accessibilityRating
                                              ? const Color(0xFF4CAF50)
                                              : subtitleColor.withOpacity(0.3),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openItemDetail(ItineraryItem item) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => ItineraryDetailScreen(item: item),
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark, Color cardColor, Color textColor) {
    final acceptedCount = _generatedItinerary.where((i) => i.isAccepted).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$acceptedCount activities selected',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.7),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Confirm your itinerary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            enabled: acceptedCount > 0,
            label: 'Confirm itinerary with $acceptedCount activities',
            hint:
                acceptedCount == 0
                    ? 'Select at least one activity first'
                    : 'Tap to finalize your itinerary',
            child: GestureDetector(
              onTap: acceptedCount > 0 ? _confirmItinerary : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient:
                      acceptedCount > 0
                          ? const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          )
                          : null,
                  color:
                      acceptedCount == 0
                          ? (isDark
                              ? Colors.white.withOpacity(0.1)
                              : const Color(0xFFE5E5EA))
                          : null,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        acceptedCount > 0
                            ? Colors.white
                            : (isDark
                                ? Colors.white38
                                : const Color(0xFF8E8E93)),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== DATA MODELS ====================

enum ItineraryPlannerPhase { chat, generating, review, confirmed }

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<QuickReply>? quickReplies;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickReplies,
  });
}

class QuickReply {
  final String label;
  final String value;
  final bool isMultiSelect;

  QuickReply({
    required this.label,
    required this.value,
    this.isMultiSelect = false,
  });
}

class ItineraryItem {
  final String id;
  final int day;
  final String title;
  final String time;
  final String description;
  final String imageEmoji;
  final String location;
  final int accessibilityRating;
  final String accessibilityNotes;
  final List<String> tags;
  final String estimatedCost;
  final String altText;
  final bool isAccepted;

  ItineraryItem({
    required this.id,
    required this.day,
    required this.title,
    required this.time,
    required this.description,
    required this.imageEmoji,
    required this.location,
    required this.accessibilityRating,
    required this.accessibilityNotes,
    required this.tags,
    required this.estimatedCost,
    required this.altText,
    this.isAccepted = true,
  });

  ItineraryItem copyWith({
    String? id,
    int? day,
    String? title,
    String? time,
    String? description,
    String? imageEmoji,
    String? location,
    int? accessibilityRating,
    String? accessibilityNotes,
    List<String>? tags,
    String? estimatedCost,
    String? altText,
    bool? isAccepted,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      day: day ?? this.day,
      title: title ?? this.title,
      time: time ?? this.time,
      description: description ?? this.description,
      imageEmoji: imageEmoji ?? this.imageEmoji,
      location: location ?? this.location,
      accessibilityRating: accessibilityRating ?? this.accessibilityRating,
      accessibilityNotes: accessibilityNotes ?? this.accessibilityNotes,
      tags: tags ?? this.tags,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      altText: altText ?? this.altText,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}
