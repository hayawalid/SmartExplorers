import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';

/// Egypt-Themed Itinerary Planner combining AI chat and destination cards
/// Color Palette: Desert Sand, Nile Blue, Ancient Gold, Warm Terracotta
class ItineraryPlannerScreen extends StatefulWidget {
  const ItineraryPlannerScreen({Key? key}) : super(key: key);

  @override
  State<ItineraryPlannerScreen> createState() => _ItineraryPlannerScreenState();
}

class _ItineraryPlannerScreenState extends State<ItineraryPlannerScreen>
    with TickerProviderStateMixin {
  // Egypt-inspired color palette
  static const Color desertSand = Color(0xFFE8D5B7);
  static const Color nileBlue = Color(0xFF4A90A4);
  static const Color paleNileBlue = Color(0xFF87CEEB);
  static const Color ancientGold = Color(0xFFD4AF37);
  static const Color warmTerracotta = Color(0xFFB85C38);
  static const Color softCream = Color(0xFFFAF3E0);
  static const Color deepBrown = Color(0xFF5D4037);

  // State management
  ItineraryPlannerPhase _currentPhase = ItineraryPlannerPhase.chat;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _cardsScrollController = ScrollController();

  // Animation controllers
  late AnimationController _loadingAnimController;
  late AnimationController _cardRevealController;
  late AnimationController _chatToggleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _chatSlideAnimation;

  // Chat messages
  final List<ChatMessage> _messages = [];

  // User preferences
  String? _selectedGender;
  List<String> _selectedAccessibilityNeeds = [];
  List<String> _selectedInterests = [];

  // Generated itinerary
  List<ItineraryItem> _generatedItinerary = [];
  int _currentRevealIndex = 0;

  // UI State
  bool _isChatExpanded = true;
  String? _expandedCardId;

  // Suggested prompts (like Travelioo AI)
  final List<SuggestedPrompt> _suggestedPrompts = [
    SuggestedPrompt(
      icon: '🏺',
      title: 'Historical sites',
      subtitle: '5 days in Cairo',
    ),
    SuggestedPrompt(
      icon: '🏖️',
      title: 'Beach getaway',
      subtitle: 'Red Sea resort',
    ),
    SuggestedPrompt(
      icon: '🏛️',
      title: 'Ancient wonders',
      subtitle: 'Pyramids & temples',
    ),
  ];

  // Quick options
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

    _chatToggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _loadingAnimController, curve: Curves.easeInOut),
    );

    _chatSlideAnimation = CurvedAnimation(
      parent: _chatToggleController,
      curve: Curves.easeInOutCubic,
    );

    // Initial greeting
    _addBotMessage(
      "Good morning! 🌅 I'm your Egypt travel assistant. Let me help you plan a perfect journey through Egypt's wonders.",
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _askGenderPreference();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _cardsScrollController.dispose();
    _loadingAnimController.dispose();
    _cardRevealController.dispose();
    _chatToggleController.dispose();
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

  void _toggleChat() {
    setState(() {
      _isChatExpanded = !_isChatExpanded;
    });
    if (_isChatExpanded) {
      _chatToggleController.forward();
    } else {
      _chatToggleController.reverse();
    }
    HapticFeedback.mediumImpact();
  }

  void _expandCard(String cardId) {
    setState(() {
      _expandedCardId = cardId;
    });
    HapticFeedback.mediumImpact();
  }

  void _collapseCard() {
    setState(() {
      _expandedCardId = null;
    });
    HapticFeedback.lightImpact();
  }

  /// Handle free-form user messages - allows chatting at any time
  void _handleUserMessage(String message) {
    if (message.trim().isEmpty) return;

    HapticFeedback.lightImpact();
    _addUserMessage(message);
    _messageController.clear();

    // Simulate AI response based on message content
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;

      final lowerMessage = message.toLowerCase();

      // Check for common travel questions and provide contextual responses
      if (lowerMessage.contains('pyramid') || lowerMessage.contains('giza')) {
        _addBotMessage(
          "The Pyramids of Giza are a must-see! 🏛️ The complex includes the Great Pyramid (Khufu), the Pyramid of Khafre, and the Pyramid of Menkaure. Best time to visit is early morning (6-8 AM) to avoid crowds and heat. Would you like me to add this to your itinerary?",
        );
      } else if (lowerMessage.contains('luxor') ||
          lowerMessage.contains('temple')) {
        _addBotMessage(
          "Luxor is incredible! ⚱️ Known as the 'world's greatest open-air museum,' you can explore the Karnak Temple, Luxor Temple, and the Valley of the Kings. I'd recommend 2-3 days there. Want me to plan a Luxor extension for you?",
        );
      } else if (lowerMessage.contains('food') ||
          lowerMessage.contains('eat') ||
          lowerMessage.contains('restaurant')) {
        _addBotMessage(
          "Egyptian cuisine is delicious! 🍽️ Must-try dishes include Koshari (Egypt's national dish), Ful Medames, and fresh seafood in Alexandria. I can recommend restaurants based on your location and dietary preferences. Where will you be dining?",
        );
      } else if (lowerMessage.contains('safe') ||
          lowerMessage.contains('security')) {
        _addBotMessage(
          "Safety is our priority! 🛡️ Egypt is generally safe for tourists, especially in tourist areas. Our verified guides and the SmartExplorers safety features provide real-time assistance. All our partner services are thoroughly vetted.",
        );
      } else if (lowerMessage.contains('cost') ||
          lowerMessage.contains('price') ||
          lowerMessage.contains('budget')) {
        _addBotMessage(
          "Budget planning is important! 💰 A typical day in Egypt costs \$50-150 depending on your style. Entry fees range \$10-25, meals \$5-20, and private guides \$50-100/day. I can create an itinerary matching your budget preferences.",
        );
      } else if (lowerMessage.contains('weather') ||
          lowerMessage.contains('when') ||
          lowerMessage.contains('best time')) {
        _addBotMessage(
          "Great question! 🌡️ The best time to visit Egypt is October to April when temperatures are comfortable (15-25°C). Summer months (June-August) can be very hot (35-45°C). For Nile cruises, December-February is ideal.",
        );
      } else if (lowerMessage.contains('generate') ||
          lowerMessage.contains('create') ||
          lowerMessage.contains('plan') ||
          lowerMessage.contains('itinerary')) {
        _addBotMessage(
          "I'd love to create your personalized itinerary! ✨ To give you the best recommendations, I just need to know a few things about your preferences. Let me ask you some quick questions...",
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _askGenderPreference();
        });
      } else {
        // Generic helpful response
        _addBotMessage(
          "That's interesting! 🌍 I'm here to help you plan the perfect Egyptian adventure. You can ask me about:\n\n• Popular destinations (Pyramids, Luxor, Red Sea)\n• Local cuisine and restaurants\n• Safety and travel tips\n• Budget and pricing\n• Best times to visit\n\nOr say 'create my itinerary' to start planning!",
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
      "Do you have any accessibility needs? This helps me recommend suitable activities.",
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
      "What interests you most about Egypt? 🏺",
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
    _addBotMessage("Wonderful! Creating your personalized Egypt journey...");

    setState(() => _currentPhase = ItineraryPlannerPhase.generating);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _generateItinerary();
        setState(() {
          _currentPhase = ItineraryPlannerPhase.review;
          _isChatExpanded = false;
        });
        _chatToggleController.reverse();
        _revealCardsSequentially();
      }
    });
  }

  void _generateItinerary() {
    _generatedItinerary = [
      ItineraryItem(
        id: '1',
        day: 1,
        title: 'Pyramids of Giza',
        time: '6:00 AM - 12:00 PM',
        description:
            'Begin your Egyptian odyssey at the iconic Pyramids of Giza. Stand before the Great Pyramid, one of the Seven Wonders, and witness the enigmatic Sphinx. Experience the golden hour as the sun rises over these ancient monuments.',
        imageUrl:
            'https://images.unsplash.com/photo-1572252009286-268acec5ca0a',
        location: 'Giza Plateau, Cairo',
        accessibilityRating: 3,
        accessibilityNotes:
            'Wheelchair accessible paths available at main viewing areas. Some sandy terrain.',
        tags: ['Ancient History', 'Photography', 'UNESCO Site'],
        estimatedCost: '\$25',
        pricePerDay: '25',
        rating: 4.8,
        reviewCount: 2847,
      ),
      ItineraryItem(
        id: '2',
        day: 1,
        title: 'Egyptian Museum',
        time: '2:00 PM - 5:00 PM',
        description:
            'Discover treasures spanning 5,000 years at the Egyptian Museum in Tahrir Square. Marvel at King Tutankhamun\'s golden mask, royal mummies, and countless artifacts that bring ancient Egypt to life.',
        imageUrl: 'https://images.unsplash.com/photo-1553913861-c0fddf2619ee',
        location: 'Tahrir Square, Cairo',
        accessibilityRating: 4,
        accessibilityNotes:
            'Fully accessible with elevators, ramps, and audio guides available.',
        tags: ['Museums', 'Ancient History', 'Cultural'],
        estimatedCost: '\$15',
        pricePerDay: '15',
        rating: 4.7,
        reviewCount: 1923,
      ),
      ItineraryItem(
        id: '3',
        day: 2,
        title: 'Nile River Cruise',
        time: '5:00 PM - 9:00 PM',
        description:
            'Sail along the legendary Nile River at sunset. Enjoy traditional Egyptian cuisine, live music, and mesmerizing belly dance performances as Cairo\'s skyline twinkles in the evening light.',
        imageUrl:
            'https://images.unsplash.com/photo-1568322445389-f64ac2515020',
        location: 'Nile River, Cairo',
        accessibilityRating: 4,
        accessibilityNotes:
            'Modern boats with accessible boarding, restrooms, and seating areas.',
        tags: ['Relaxation', 'Food & Dining', 'Entertainment'],
        estimatedCost: '\$60',
        pricePerDay: '60',
        rating: 4.6,
        reviewCount: 1547,
      ),
      ItineraryItem(
        id: '4',
        day: 2,
        title: 'Khan el-Khalili Bazaar',
        time: '10:00 AM - 1:00 PM',
        description:
            'Wander through Cairo\'s vibrant 14th-century marketplace. Browse handcrafted jewelry, aromatic spices, colorful textiles, and traditional souvenirs in this atmospheric bazaar.',
        imageUrl: 'https://images.unsplash.com/photo-1547036967-23d11aacaee0',
        location: 'Islamic Cairo',
        accessibilityRating: 2,
        accessibilityNotes:
            'Narrow streets and crowds. Limited wheelchair access in historic areas.',
        tags: ['Shopping', 'Cultural', 'Local Experience'],
        estimatedCost: '\$40',
        pricePerDay: '40',
        rating: 4.5,
        reviewCount: 2134,
      ),
      ItineraryItem(
        id: '5',
        day: 3,
        title: 'Alexandria Day Trip',
        time: '7:00 AM - 7:00 PM',
        description:
            'Journey to Egypt\'s Mediterranean gem. Visit the modern Bibliotheca Alexandrina, historic Qaitbay Citadel, and ancient Roman catacombs. Savor fresh seafood along the scenic corniche.',
        imageUrl:
            'https://images.unsplash.com/photo-1568633228165-17c52a3aa732',
        location: 'Alexandria, Mediterranean Coast',
        accessibilityRating: 4,
        accessibilityNotes:
            'Modern facilities with good accessibility at major attractions.',
        tags: ['History', 'Coastal', 'Architecture'],
        estimatedCost: '\$85',
        pricePerDay: '85',
        rating: 4.7,
        reviewCount: 1689,
      ),
    ];
  }

  void _revealCardsSequentially() {
    _currentRevealIndex = 0;
    Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (_currentRevealIndex < _generatedItinerary.length) {
        setState(() => _currentRevealIndex++);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleAcceptDeny(String itemId, bool accept) {
    HapticFeedback.mediumImpact();
    setState(() {
      final index = _generatedItinerary.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _generatedItinerary[index] = _generatedItinerary[index].copyWith(
          isAccepted: accept,
        );
      }
    });
  }

  void _confirmItinerary() {
    HapticFeedback.heavyImpact();
    setState(() => _currentPhase = ItineraryPlannerPhase.confirmed);

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Journey Confirmed! ✨'),
            content: const Text(
              'Your Egyptian adventure awaits. Safe travels!',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('View Itinerary'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1410) : softCream;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(child: _buildCardsArea(isDark)),
                _buildChatSection(isDark),
              ],
            ),
          ),
          if (_expandedCardId != null) _buildExpandedCard(isDark),
          if (_currentPhase == ItineraryPlannerPhase.generating)
            _buildGeneratingOverlay(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final textColor = isDark ? softCream : deepBrown;
    final acceptedCount = _generatedItinerary.where((i) => i.isAccepted).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A1F1A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color:
                isDark
                    ? Colors.white.withOpacity(0.05)
                    : desertSand.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: nileBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(CupertinoIcons.back, color: nileBlue, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Journey',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    fontFamily: 'SF Pro Display',
                    letterSpacing: -0.3,
                  ),
                ),
                if (_generatedItinerary.isNotEmpty)
                  Text(
                    '$acceptedCount destination${acceptedCount != 1 ? 's' : ''} selected',
                    style: TextStyle(
                      fontSize: 13,
                      color: nileBlue.withOpacity(0.8),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
              ],
            ),
          ),
          if (_generatedItinerary.isNotEmpty && acceptedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [nileBlue, nileBlue.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Day ${_generatedItinerary.last.day}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardsArea(bool isDark) {
    if (_generatedItinerary.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.builder(
      controller: _cardsScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _currentRevealIndex,
      itemBuilder: (context, index) {
        final item = _generatedItinerary[index];
        return _buildDestinationCard(item, index, isDark);
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final textColor = isDark ? softCream : deepBrown;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: desertSand.withOpacity(isDark ? 0.1 : 0.3),
            ),
            child: Center(
              child: Text('🏺', style: const TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Crafting your journey...',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: textColor.withOpacity(0.7),
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Through ancient lands',
            style: TextStyle(
              fontSize: 14,
              color: nileBlue.withOpacity(0.6),
              fontFamily: 'SF Pro Text',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(ItineraryItem item, int index, bool isDark) {
    final cardBg = isDark ? const Color(0xFF2A1F1A) : Colors.white;
    final textColor = isDark ? softCream : deepBrown;
    final subtitleColor =
        isDark ? desertSand.withOpacity(0.6) : const Color(0xFF8B7355);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => _expandCard(item.id),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image header
                      Stack(
                        children: [
                          // Destination image
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              color: desertSand.withOpacity(0.3),
                              child: Center(
                                child: Icon(
                                  CupertinoIcons.photo,
                                  size: 48,
                                  color: nileBlue.withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                          // Gradient overlay
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Day badge
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: nileBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Day ${item.day}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ),
                          ),
                          // Bookmark toggle
                          Positioned(
                            top: 12,
                            right: 12,
                            child: _buildAcceptDenyButton(item, isDark),
                          ),
                          // Title overlay
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'SF Pro Display',
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
                            // Location and rating
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.location_fill,
                                  size: 14,
                                  color: nileBlue,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.location,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: subtitleColor,
                                      fontFamily: 'SF Pro Text',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.star_fill,
                                  size: 14,
                                  color: ancientGold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.rating}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                                Text(
                                  ' (${item.reviewCount})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtitleColor,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Description preview
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: textColor.withOpacity(0.8),
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Time and price
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: 14,
                                  color: subtitleColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.time.split(' - ')[0],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtitleColor,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: nileBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item.estimatedCost} / day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: nileBlue,
                                      fontFamily: 'SF Pro Text',
                                    ),
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
        );
      },
    );
  }

  Widget _buildAcceptDenyButton(ItineraryItem item, bool isDark) {
    return GestureDetector(
      onTap: () => _handleAcceptDeny(item.id, !item.isAccepted),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color:
              item.isAccepted
                  ? ancientGold
                  : (isDark ? Colors.black54 : Colors.white),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
          ],
        ),
        child: Icon(
          item.isAccepted
              ? CupertinoIcons.bookmark_fill
              : CupertinoIcons.bookmark,
          size: 18,
          color: item.isAccepted ? Colors.white : nileBlue,
        ),
      ),
    );
  }

  Widget _buildChatSection(bool isDark) {
    final cardBg = isDark ? const Color(0xFF2A1F1A) : Colors.white;
    // Add bottom padding for navigation bar (80 height + 30 bottom + some margin)
    final bottomPadding = MediaQuery.of(context).padding.bottom + 120;

    return AnimatedBuilder(
      animation: _chatSlideAnimation,
      builder: (context, child) {
        final chatHeight = 450.0 * _chatSlideAnimation.value;

        return Container(
          height: _isChatExpanded ? chatHeight : 75,
          margin: EdgeInsets.only(
            bottom: _isChatExpanded ? bottomPadding : bottomPadding,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildChatToggleHeader(isDark),
              if (_isChatExpanded) Expanded(child: _buildChatContent(isDark)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatToggleHeader(bool isDark) {
    final textColor = isDark ? softCream : deepBrown;

    return GestureDetector(
      onTap: _toggleChat,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // AI Avatar with Egypt theme
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [nileBlue, paleNileBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: nileBlue.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text('🏺', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Egypt Travel AI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  Text(
                    _isChatExpanded
                        ? 'Planning your journey...'
                        : 'Tap to chat with assistant',
                    style: TextStyle(
                      fontSize: 13,
                      color: nileBlue.withOpacity(0.7),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _isChatExpanded
                  ? CupertinoIcons.chevron_down
                  : CupertinoIcons.chevron_up,
              color: nileBlue,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent(bool isDark) {
    final textColor = isDark ? softCream : deepBrown;
    final bgColor = isDark ? const Color(0xFF1A1410) : softCream;

    return Column(
      children: [
        // Suggested prompts (shown when no messages yet)
        if (_messages.length <= 2 &&
            _currentPhase == ItineraryPlannerPhase.chat)
          _buildSuggestedPrompts(isDark),

        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildChatBubble(message, isDark);
            },
          ),
        ),

        // Input area - Always visible for free-form chat
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color:
                    isDark
                        ? Colors.white.withOpacity(0.05)
                        : desertSand.withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2A1F1A) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: desertSand.withOpacity(0.2)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'SF Pro Text',
                      fontSize: 15,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _handleUserMessage,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything about Egypt...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  if (_messageController.text.isNotEmpty) {
                    _handleUserMessage(_messageController.text);
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [nileBlue, paleNileBlue]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: nileBlue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
      ],
    );
  }

  Widget _buildSuggestedPrompts(bool isDark) {
    final textColor = isDark ? softCream : deepBrown;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('✨', style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'How can we help?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: nileBlue,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Suggested prompts',
            style: TextStyle(
              fontSize: 13,
              color: textColor.withOpacity(0.5),
              fontFamily: 'SF Pro Text',
            ),
          ),
          const SizedBox(height: 12),
          ...(_suggestedPrompts.take(3).map((prompt) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  _addUserMessage('${prompt.title} - ${prompt.subtitle}');
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF2A1F1A)
                            : desertSand.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: desertSand.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(prompt.icon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prompt.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                            Text(
                              prompt.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: textColor.withOpacity(0.6),
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isDark) {
    final isUser = message.isUser;
    final bubbleColor =
        isUser
            ? nileBlue
            : (isDark ? const Color(0xFF2A1F1A) : desertSand.withOpacity(0.3));
    final textColor = isUser ? Colors.white : (isDark ? softCream : deepBrown);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                fontFamily: 'SF Pro Text',
                height: 1.4,
              ),
            ),
          ),

          if (message.quickReplies != null && message.quickReplies!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildQuickReplies(message.quickReplies!, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(List<QuickReply> replies, bool isDark) {
    final isMultiSelect = replies.first.isMultiSelect;
    final selectedValues = <String>[];

    if (isMultiSelect) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    replies.map((reply) {
                      final isSelected = selectedValues.contains(reply.value);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedValues.remove(reply.value);
                            } else {
                              selectedValues.add(reply.value);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? nileBlue
                                    : (isDark
                                        ? const Color(0xFF2A1F1A)
                                        : Colors.white),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? nileBlue
                                      : desertSand.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            reply.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : (isDark ? softCream : deepBrown),
                              fontFamily: 'SF Pro Text',
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
              if (selectedValues.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: GestureDetector(
                    onTap: () {
                      if (replies.first.value == _accessibilityOptions.first) {
                        _handleAccessibilitySelection(selectedValues);
                      } else if (replies.first.value ==
                          _interestOptions.first) {
                        _handleInterestsSelection(selectedValues);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [nileBlue, paleNileBlue],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: nileBlue.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Continue',
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
            ],
          );
        },
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          replies.map((reply) {
            return GestureDetector(
              onTap: () => _handleGenderSelection(reply.value),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A1F1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: desertSand.withOpacity(0.4)),
                ),
                child: Text(
                  reply.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? softCream : deepBrown,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildExpandedCard(bool isDark) {
    final item = _generatedItinerary.firstWhere((i) => i.id == _expandedCardId);
    final textColor = isDark ? softCream : deepBrown;
    final subtitleColor =
        isDark ? desertSand.withOpacity(0.6) : const Color(0xFF8B7355);

    return GestureDetector(
      onTap: _collapseCard,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: SafeArea(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A1F1A) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Image header
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          child: Container(
                            height: 250,
                            width: double.infinity,
                            color: desertSand.withOpacity(0.3),
                            child: Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                size: 64,
                                color: nileBlue.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: GestureDetector(
                            onTap: _collapseCard,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.xmark,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: nileBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Day ${item.day}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontFamily: 'SF Pro Display',
                                  shadows: [
                                    Shadow(
                                      color: Colors.black45,
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Location and rating row
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.location_fill,
                                  size: 16,
                                  color: nileBlue,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.location,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subtitleColor,
                                      fontFamily: 'SF Pro Text',
                                    ),
                                  ),
                                ),
                                Icon(
                                  CupertinoIcons.star_fill,
                                  size: 16,
                                  color: ancientGold,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${item.rating} (${item.reviewCount})',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Time
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: 16,
                                  color: subtitleColor,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.time,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: subtitleColor,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Description
                            Text(
                              'About this experience',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: textColor.withOpacity(0.85),
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Cost
                            Text(
                              'Pricing',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: nileBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: nileBlue.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.money_dollar_circle_fill,
                                    size: 24,
                                    color: nileBlue,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${item.pricePerDay}\$ per day',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: nileBlue,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Accessibility
                            Text(
                              'Accessibility',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: List.generate(5, (index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    index < item.accessibilityRating
                                        ? CupertinoIcons.person_crop_circle_fill
                                        : CupertinoIcons.person_crop_circle,
                                    size: 24,
                                    color:
                                        index < item.accessibilityRating
                                            ? nileBlue
                                            : subtitleColor.withOpacity(0.3),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.accessibilityNotes,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: subtitleColor,
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Tags
                            Text(
                              'Highlights',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  item.tags.map((tag) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: desertSand.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: desertSand.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                          fontFamily: 'SF Pro Text',
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom action
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color:
                                isDark
                                    ? Colors.white.withOpacity(0.05)
                                    : desertSand.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _handleAcceptDeny(item.id, true);
                          _collapseCard();
                          HapticFeedback.mediumImpact();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [nileBlue, paleNileBlue],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: nileBlue.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                CupertinoIcons.bookmark_fill,
                                size: 20,
                                color: Colors.white,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add to Journey',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildGeneratingOverlay(bool isDark) {
    return Container(
      color: (isDark ? const Color(0xFF1A1410) : softCream).withOpacity(0.95),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [nileBlue, paleNileBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: nileBlue.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🏺', style: TextStyle(fontSize: 52)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Crafting your journey...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? softCream : deepBrown,
                  fontFamily: 'SF Pro Display',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Through the wonders of Egypt ✨',
                style: TextStyle(
                  fontSize: 15,
                  color: nileBlue.withOpacity(0.8),
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
        ),
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

class SuggestedPrompt {
  final String icon;
  final String title;
  final String subtitle;

  SuggestedPrompt({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class ItineraryItem {
  final String id;
  final int day;
  final String title;
  final String time;
  final String description;
  final String imageUrl;
  final String location;
  final int accessibilityRating;
  final String accessibilityNotes;
  final List<String> tags;
  final String estimatedCost;
  final String pricePerDay;
  final double rating;
  final int reviewCount;
  final bool isAccepted;

  ItineraryItem({
    required this.id,
    required this.day,
    required this.title,
    required this.time,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.accessibilityRating,
    required this.accessibilityNotes,
    required this.tags,
    required this.estimatedCost,
    required this.pricePerDay,
    required this.rating,
    required this.reviewCount,
    this.isAccepted = true,
  });

  ItineraryItem copyWith({
    String? id,
    int? day,
    String? title,
    String? time,
    String? description,
    String? imageUrl,
    String? location,
    int? accessibilityRating,
    String? accessibilityNotes,
    List<String>? tags,
    String? estimatedCost,
    String? pricePerDay,
    double? rating,
    int? reviewCount,
    bool? isAccepted,
  }) {
    return ItineraryItem(
      id: id ?? this.id,
      day: day ?? this.day,
      title: title ?? this.title,
      time: time ?? this.time,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      accessibilityRating: accessibilityRating ?? this.accessibilityRating,
      accessibilityNotes: accessibilityNotes ?? this.accessibilityNotes,
      tags: tags ?? this.tags,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }
}
