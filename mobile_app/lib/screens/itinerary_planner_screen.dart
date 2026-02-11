import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'dart:async';
import '../theme/app_theme.dart';

/// Tab 1: AI Itinerary Planner
/// Top 60%: Dynamic ListView of destination cards with glassmorphism overlay
/// Bottom 40%: Chat interface with sample-prompt chips
class ItineraryPlannerScreen extends StatefulWidget {
  const ItineraryPlannerScreen({Key? key}) : super(key: key);

  @override
  State<ItineraryPlannerScreen> createState() => _ItineraryPlannerScreenState();
}

class _ItineraryPlannerScreenState extends State<ItineraryPlannerScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _cardScroll = ScrollController();
  final ScrollController _chatScroll = ScrollController();
  final List<_ChatMsg> _messages = [];
  bool _isTyping = false;

  // Sample itinerary cards
  final List<_ItineraryCard> _cards = const [
    _ItineraryCard(
      title: 'Pyramids of Giza',
      date: 'Mar 14 \u00b7 6 AM \u2013 12 PM',
      bio: 'Stand before 4 500 years of wonder on the Giza Plateau.',
      emoji: '\ud83c\udfdb\ufe0f',
    ),
    _ItineraryCard(
      title: 'Luxor Temple',
      date: 'Mar 15 \u00b7 8 AM \u2013 11 AM',
      bio: 'Walk among colossal columns built by Amenhotep III.',
      emoji: '\u26b1\ufe0f',
    ),
    _ItineraryCard(
      title: 'Red Sea Dive',
      date: 'Mar 16 \u00b7 9 AM \u2013 2 PM',
      bio: 'Discover vibrant coral reefs and exotic marine life.',
      emoji: '\ud83d\udc20',
    ),
    _ItineraryCard(
      title: 'Valley of the Kings',
      date: 'Mar 15 \u00b7 1 PM \u2013 4 PM',
      bio: 'Descend into the burial chambers of ancient pharaohs.',
      emoji: '\ud83d\udc51',
    ),
    _ItineraryCard(
      title: 'Khan el-Khalili',
      date: 'Mar 14 \u00b7 6 PM \u2013 9 PM',
      bio: 'Bustling medieval marketplace with spices & lanterns.',
      emoji: '\ud83d\udecd\ufe0f',
    ),
  ];

  static const _samplePrompts = [
    'Find 3-day Tokyo food tour',
    'Weekend getaway near Cairo',
    'Solo female-friendly itinerary',
    'Budget trip under \$500',
    'Family-friendly Luxor plan',
    'Adventure in the Red Sea',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMsg(
        text:
            'Hello! \ud83c\udf0d I\u0027m your AI travel assistant. '
            'Tell me where and when you\u0027d like to go, '
            'and I\u0027ll craft the perfect itinerary.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _cardScroll.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_ChatMsg(text: text.trim(), isUser: true));
      _isTyping = true;
    });
    _msgController.clear();
    _scrollChat();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMsg(
            text:
                'Great choice! I\u0027ve updated your itinerary cards above. '
                'Swipe through to review each stop.',
            isUser: false,
          ),
        );
      });
      _scrollChat();
    });
  }

  void _scrollChat() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.pureWhite;
    final textColor = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = isDark ? Colors.white54 : AppDesign.midGrey;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    color: AppDesign.electricCobalt,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI Planner',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: textColor),
                  ),
                  const Spacer(),
                  _pill(isDark, 'Cairo \u00b7 3 days', sub),
                ],
              ),
            ),
            // Top 60%: Cards
            Expanded(flex: 6, child: _buildCardList(isDark)),
            Divider(
              height: 1,
              color: isDark ? Colors.white10 : AppDesign.lightGrey,
            ),
            // Bottom 40%: Chat
            Expanded(flex: 4, child: _buildChat(isDark, textColor)),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 88),
          ],
        ),
      ),
    );
  }

  Widget _buildCardList(bool isDark) {
    return ListView.builder(
      controller: _cardScroll,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _cards.length,
      itemBuilder:
          (_, i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CardWidget(card: _cards[i], isDark: isDark),
          ),
    );
  }

  Widget _buildChat(bool isDark, Color text) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScroll,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == _messages.length && _isTyping) return _typing(isDark);
              return _bubble(_messages[i], isDark);
            },
          ),
        ),
        // Prompt chips
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _samplePrompts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder:
                (_, i) => ActionChip(
                  label: Text(
                    _samplePrompts[i],
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : AppDesign.eerieBlack,
                    ),
                  ),
                  backgroundColor:
                      isDark ? AppDesign.darkGrey : AppDesign.offWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDesign.radius),
                    side: BorderSide(
                      color: isDark ? Colors.white10 : AppDesign.lightGrey,
                    ),
                  ),
                  onPressed: () => _send(_samplePrompts[i]),
                ),
          ),
        ),
        const SizedBox(height: 8),
        // Input bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppDesign.darkGrey : AppDesign.offWhite,
                    borderRadius: AppDesign.borderRadius,
                  ),
                  child: TextField(
                    controller: _msgController,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white : AppDesign.eerieBlack,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Describe your dream trip\u2026',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white38 : AppDesign.midGrey,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                    onSubmitted: _send,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _send(_msgController.text),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppDesign.electricCobalt,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.send,
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

  Widget _bubble(_ChatMsg msg, bool isDark) {
    final w = MediaQuery.of(context).size.width * 0.72;
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: w),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              msg.isUser
                  ? AppDesign.electricCobalt
                  : (isDark ? AppDesign.darkGrey : AppDesign.offWhite),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color:
                msg.isUser
                    ? Colors.white
                    : (isDark ? Colors.white : AppDesign.eerieBlack),
          ),
        ),
      ),
    );
  }

  Widget _typing(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppDesign.darkGrey : AppDesign.offWhite,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: SizedBox(
          width: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) => _dot(i)),
          ),
        ),
      ),
    );
  }

  Widget _dot(int i) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + i * 200),
      builder:
          (_, v, __) => Opacity(
            opacity: 0.3 + 0.7 * v,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppDesign.electricCobalt.withOpacity(0.6),
              ),
            ),
          ),
    );
  }

  Widget _pill(bool isDark, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppDesign.darkGrey : AppDesign.offWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : AppDesign.lightGrey,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

// Card widget with glassmorphism text overlay
class _CardWidget extends StatelessWidget {
  const _CardWidget({required this.card, required this.isDark});
  final _ItineraryCard card;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: AppDesign.borderRadius,
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: ClipRRect(
        borderRadius: AppDesign.borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isDark
                          ? [const Color(0xFF1E1E2E), const Color(0xFF2A2A3E)]
                          : [const Color(0xFFE8ECFF), const Color(0xFFF0F4FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(card.emoji, style: const TextStyle(fontSize: 64)),
              ),
            ),
            // Gradient scrim
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
            ),
            // Glass overlay
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: AppDesign.glassmorphism(isDark: true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          card.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.bio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItineraryCard {
  const _ItineraryCard({
    required this.title,
    required this.date,
    required this.bio,
    required this.emoji,
  });
  final String title, date, bio, emoji;
}

class _ChatMsg {
  _ChatMsg({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

/// Model used by ItineraryDetailScreen
class ItineraryItem {
  const ItineraryItem({
    required this.id,
    required this.title,
    required this.location,
    required this.time,
    required this.estimatedCost,
    required this.description,
    required this.day,
    required this.imageEmoji,
    this.altText = '',
    this.isAccepted = false,
    this.accessibilityRating = 3,
    this.accessibilityNotes = '',
    this.tags = const [],
  });

  final String id;
  final String title;
  final String location;
  final String time;
  final String estimatedCost;
  final String description;
  final int day;
  final String imageEmoji;
  final String altText;
  final bool isAccepted;
  final int accessibilityRating;
  final String accessibilityNotes;
  final List<String> tags;
}
