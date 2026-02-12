import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'dart:async';
import '../theme/app_theme.dart';
import '../widgets/smart_explorers_logo.dart';
import '../services/planner_api_service.dart';
import '../services/profile_api_service.dart';
import '../services/session_store.dart';
import 'itinerary_calendar_screen.dart'; // Import the calendar screen

/// Agentic AI Itinerary Planner
/// Starts as chat-only, shows suggestion cards when AI creates itineraries
class ItineraryPlannerScreen extends StatefulWidget {
  const ItineraryPlannerScreen({Key? key}) : super(key: key);

  @override
  State<ItineraryPlannerScreen> createState() => _ItineraryPlannerScreenState();
}

class _ItineraryPlannerScreenState extends State<ItineraryPlannerScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();
  final List<_ChatItem> _chatItems = [];
  bool _isTyping = false;

  // Real API state
  String? _conversationId;
  Map<String, dynamic>? _lastItinerary; // Stores the latest generated itinerary

  // User profile context for personalized responses
  final ProfileApiService _profileService = ProfileApiService();
  Map<String, dynamic>? _userContext;

  // Sample prompt chips (Egypt-focused)
  static const _samplePrompts = [
    'Plan a 3-day Cairo trip',
    'Weekend in Luxor & Aswan',
    'Family trip to Hurghada',
    'Budget trip under \$300',
    'Solo female trip to Egypt',
    'Historical tour of Egypt',
  ];

  @override
  void initState() {
    super.initState();
    _chatItems.add(
      _ChatItem.message(
        text:
            'Hello! 🌍 I\'m your AI travel assistant. '
            'Tell me where you\'d like to go, and I\'ll create the perfect itinerary for you.',
        isUser: false,
      ),
    );
    _loadUserContext();
  }

  /// Fetch user + traveler/provider profile to pass as context to the LLM.
  Future<void> _loadUserContext() async {
    try {
      final session = SessionStore.instance;
      final username = session.username;
      final userId = session.userId;
      if (username == null || userId == null) return;

      // Fetch base user record
      final user = await _profileService.getUserByUsername(username);

      // Build context map with fields the planner_service understands
      final ctx = <String, dynamic>{
        'gender': user['gender'] ?? '',
        'nationality': user['nationality'] ?? user['country_of_origin'] ?? '',
        'preferred_language': user['preferred_language'] ?? '',
      };

      // Fetch detailed profile (traveler or provider)
      final accountType = session.accountType ?? user['account_type'] ?? '';
      Map<String, dynamic>? profile;
      if (accountType == 'traveler') {
        profile = await _profileService.getTravelerProfile(userId);
      } else if (accountType == 'service_provider') {
        profile = await _profileService.getProviderProfile(userId);
      }

      if (profile != null) {
        // Accessibility & disability flags
        ctx['accessibility_needs'] = profile['accessibility_needs'];
        ctx['wheelchair_access'] = profile['wheelchair_access'] ?? false;
        ctx['visual_assistance'] = profile['visual_assistance'] ?? false;
        ctx['hearing_assistance'] = profile['hearing_assistance'] ?? false;
        ctx['mobility_support'] = profile['mobility_support'] ?? false;
        ctx['sensory_sensitivity'] = profile['sensory_sensitivity'] ?? false;

        // Travel preferences
        ctx['traveling_alone'] = profile['traveling_alone'] ?? false;
        ctx['first_time_egypt'] = profile['first_time_egypt'] ?? false;
        ctx['dietary_restrictions_flag'] = profile['dietary_restrictions_flag'] ?? false;
        ctx['dietary_restrictions'] = profile['dietary_restrictions'] ?? '';
        ctx['travel_interests'] = profile['travel_interests'] ?? profile['setup_interests'] ?? [];
        ctx['languages_spoken'] = profile['languages_spoken'] ?? profile['languages'] ?? [];
        ctx['typical_budget_min'] = profile['typical_budget_min'] ?? profile['price_range_min'];
        ctx['typical_budget_max'] = profile['typical_budget_max'] ?? profile['price_range_max'];
      }

      // Remove null / empty values to keep context clean
      ctx.removeWhere((_, v) => v == null || v == '' || v == false || (v is List && v.isEmpty));

      if (ctx.isNotEmpty) {
        setState(() => _userContext = ctx);
      }
    } catch (e) {
      // Non-fatal — planner still works, just without personalization
      debugPrint('[ItineraryPlanner] Could not load user context: $e');
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();

    setState(() {
      _chatItems.add(_ChatItem.message(text: text.trim(), isUser: true));
      _isTyping = true;
    });

    _msgController.clear();
    _scrollChat();

    // Call real backend
    _callPlanner(text.trim());
  }

  Future<void> _callPlanner(String text) async {
    try {
      final result = await PlannerApiService.instance.sendMessage(
        message: text,
        conversationId: _conversationId,
        userContext: _userContext,
      );

      if (!mounted) return;

      _conversationId = result['conversation_id'] as String?;
      final mode = result['mode'] as String? ?? 'chat';
      final message = result['message'] as String? ?? '';
      // suggestions are available in result['suggestions'] for future use
      final itinerary = result['itinerary'] as Map<String, dynamic>?;

      setState(() {
        _isTyping = false;

        // Always add the text message from the LLM
        _chatItems.add(_ChatItem.message(text: message, isUser: false));

        if (mode == 'itinerary' && itinerary != null) {
          _lastItinerary = itinerary;

          // Add divider
          _chatItems.add(_ChatItem.divider(text: 'Planner'));

          // Build cards from daily_plans
          final dailyPlans = itinerary['daily_plans'] as List<dynamic>? ?? [];
          int cardIdx = 0;
          for (final dayPlan in dailyPlans) {
            final activities = (dayPlan['activities'] as List<dynamic>?) ?? [];
            final dayTitle =
                dayPlan['title'] as String? ?? 'Day ${dayPlan['day']}';
            for (final activity in activities) {
              cardIdx++;
              final costMin = activity['estimated_cost_min'];
              final costMax = activity['estimated_cost_max'];
              final priceStr =
                  costMin != null
                      ? '\$${costMin}${costMax != null ? ' - \$$costMax' : ''}'
                      : 'Free';
              final tags =
                  (activity['tags'] as List<dynamic>?)
                      ?.map((t) => t.toString())
                      .toList() ??
                  [];
              final category = activity['category'] as String? ?? 'sightseeing';
              final startTime = activity['start_time'] as String? ?? '';
              final endTime = activity['end_time'] as String? ?? '';
              final bestTimeReason =
                  activity['best_time_reason'] as String? ?? '';
              final dayDate = dayPlan['date'] as String? ?? '';
              _chatItems.add(
                _ChatItem.card(
                  suggestion: _SuggestionCard(
                    id: 'act_$cardIdx',
                    title: activity['title'] as String? ?? 'Activity',
                    subtitle: dayTitle,
                    location: activity['location_name'] as String? ?? 'Egypt',
                    price: priceStr,
                    priceUnit: '',
                    rating: 4.5,
                    imageUrl: '',
                    amenities: tags.take(4).toList(),
                    type: category,
                    date: dayDate,
                    startTime: startTime,
                    endTime: endTime,
                    bestTimeReason: bestTimeReason,
                  ),
                ),
              );
            }
          }

          // Add Apply button
          _chatItems.add(
            _ChatItem.planAction(
              planId: _conversationId ?? 'plan',
              label: 'Apply this plan to your itinerary',
            ),
          );
        }
      });

      _scrollChat();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _chatItems.add(
          _ChatItem.message(
            text:
                'Sorry, something went wrong. Please try again.\n(${e.toString()})',
            isUser: false,
          ),
        );
      });
      _scrollChat();
    }
  }

  void _applyPlan(String planId) {
    HapticFeedback.mediumImpact();

    if (_lastItinerary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No itinerary to save.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Save to database, then navigate
    _saveAndNavigate(planId);
  }

  Future<void> _saveAndNavigate(String planId) async {
    try {
      await PlannerApiService.instance.saveItinerary(
        itinerary: _lastItinerary!,
        conversationId: _conversationId,
      );

      if (!mounted) return;

      // Update the button label to show success
      for (int i = 0; i < _chatItems.length; i++) {
        if (_chatItems[i].isPlanAction &&
            _chatItems[i].planAction?.planId == planId) {
          setState(() {
            _chatItems[i] = _ChatItem.planAction(
              planId: planId,
              label: '✓ Plan saved to your itinerary',
            );
          });
          break;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✓ Itinerary saved successfully!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppDesign.electricCobalt,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to calendar screen with itinerary data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ItineraryCalendarScreen(itinerary: _lastItinerary),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDivider(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? Colors.white10 : AppDesign.lightGrey,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : AppDesign.midGrey,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: isDark ? Colors.white10 : AppDesign.lightGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanActionButton(_PlanAction action, bool isDark) {
    final isApplied = action.label.contains('✓');

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isApplied ? null : () => _applyPlan(action.planId),
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isApplied
                    ? (isDark ? AppDesign.darkGrey : AppDesign.lightGrey)
                    : AppDesign.electricCobalt,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isApplied)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(LucideIcons.check, size: 20),
                ),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      isApplied
                          ? (isDark ? Colors.white38 : AppDesign.midGrey)
                          : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _scrollChat() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(isDark, textColor),

            // Single chat view with inline cards
            Expanded(
              child: ListView.builder(
                controller: _chatScroll,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                itemCount: _chatItems.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _chatItems.length && _isTyping) {
                    return _buildTypingIndicator(isDark);
                  }

                  final item = _chatItems[i];

                  // Render based on item type
                  if (item.isMessage) {
                    return _buildChatBubble(item.message!, isDark);
                  } else if (item.isDivider) {
                    return _buildDivider(item.dividerText!, isDark);
                  } else if (item.isCard) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _SuggestionCardWidget(
                        suggestion: item.suggestion!,
                        isDark: isDark,
                        showButton: false, // No button on individual cards
                      ),
                    );
                  } else if (item.isPlanAction) {
                    return _buildPlanActionButton(item.planAction!, isDark);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),

            // Chat input
            _buildChatInput(isDark, textColor),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 88),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          const SmartExplorersLogo(size: LogoSize.tiny, showText: false),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Assistant',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Active',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(bool isDark, Color textColor) {
    final hasCards = _chatItems.any((item) => item.isCard);

    return Column(
      children: [
        // Prompt chips (show when no cards yet)
        if (!hasCards)
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
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : AppDesign.eerieBlack,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            hintStyle: TextStyle(
                              color:
                                  isDark ? Colors.white38 : AppDesign.midGrey,
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
                      IconButton(
                        icon: Icon(
                          LucideIcons.mic,
                          size: 20,
                          color: AppDesign.electricCobalt,
                        ),
                        onPressed: () {},
                      ),
                    ],
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
                    borderRadius: BorderRadius.circular(24),
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

  Widget _buildChatBubble(_ChatMessage msg, bool isDark) {
    final w = MediaQuery.of(context).size.width * 0.75;
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: w),
        margin: const EdgeInsets.only(bottom: 12),
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

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            children: List.generate(3, (i) => _buildDot(i)),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int i) {
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
}

// Suggestion Card Widget — now expandable with image background
class _SuggestionCardWidget extends StatefulWidget {
  const _SuggestionCardWidget({
    required this.suggestion,
    required this.isDark,
    this.showButton = true,
    this.onApply,
  });

  final _SuggestionCard suggestion;
  final bool isDark;
  final bool showButton;
  final VoidCallback? onApply;

  @override
  State<_SuggestionCardWidget> createState() => _SuggestionCardWidgetState();
}

class _SuggestionCardWidgetState extends State<_SuggestionCardWidget> {
  bool _expanded = false;

  static const _placeholderImages = [
    'lib/public/pexels-meryemmeva-34823948.jpg',
    'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
    'lib/public/smart_itineraries.jpg',
    'lib/public/verified_guides.jpg',
    'lib/public/pexels-ahmed-aziz-126288236-12607742.jpg',
    'lib/public/pexels-axp-photography-500641970-18934599.jpg',
    'lib/public/pexels-tima-miroshnichenko-5976728.jpg',
  ];

  String get _imageForCard {
    final hash = widget.suggestion.title.hashCode.abs();
    return _placeholderImages[hash % _placeholderImages.length];
  }

  void _toggleExpand() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = widget.suggestion;
    final isDark = widget.isDark;

    return GestureDetector(
      onTap: _toggleExpand,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background image
              Positioned.fill(
                child: Image.asset(_imageForCard, fit: BoxFit.cover),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Subtitle + rating row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            suggestion.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        // Rating badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                suggestion.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Expand indicator
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: const Icon(
                              LucideIcons.chevronDown,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Title + price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            suggestion.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          suggestion.price,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Location
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            suggestion.location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Expanded content
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: _buildExpandedContent(suggestion),
                      crossFadeState:
                          _expanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 350),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(_SuggestionCard suggestion) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time row
          if (suggestion.startTime.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 13,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${suggestion.startTime} – ${suggestion.endTime}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (suggestion.date.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    const Icon(
                      LucideIcons.calendar,
                      size: 13,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion.date,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Best time reason
          if (suggestion.bestTimeReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.lightbulb,
                    size: 13,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      suggestion.bestTimeReason,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Amenities
          if (suggestion.amenities.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children:
                  suggestion.amenities.map((a) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAmenityIcon(a),
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            a,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
        ],
      ),
    );
  }

  // Keep these methods here for the expanded card
  IconData _getAmenityIcon(String amenity) {
    if (amenity.contains('Bed')) return LucideIcons.bed;
    if (amenity.contains('Dinner') || amenity.contains('Sushi'))
      return LucideIcons.utensils;
    if (amenity.contains('Guest')) return LucideIcons.users;
    if (amenity.contains('Historic')) return LucideIcons.landmark;
    if (amenity.contains('Photo')) return LucideIcons.camera;
    if (amenity.contains('Garden')) return LucideIcons.trees;
    return LucideIcons.checkCircle;
  }
}

class _SuggestionCard {
  const _SuggestionCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.price,
    required this.priceUnit,
    required this.rating,
    required this.imageUrl,
    required this.amenities,
    required this.type,
    this.isSaved = false,
    this.date = '',
    this.startTime = '',
    this.endTime = '',
    this.bestTimeReason = '',
  });

  final String id;
  final String title;
  final String subtitle;
  final String location;
  final String price;
  final String priceUnit;
  final double rating;
  final String imageUrl;
  final List<String> amenities;
  final String type;
  final bool isSaved;
  final String date;
  final String startTime;
  final String endTime;
  final String bestTimeReason;

  _SuggestionCard copyWith({String? title, String? price, bool? isSaved}) {
    return _SuggestionCard(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle,
      location: location,
      price: price ?? this.price,
      priceUnit: priceUnit,
      rating: rating,
      imageUrl: imageUrl,
      amenities: amenities,
      type: type,
      isSaved: isSaved ?? this.isSaved,
      date: date,
      startTime: startTime,
      endTime: endTime,
      bestTimeReason: bestTimeReason,
    );
  }
}

class _ChatItem {
  const _ChatItem._({
    this.message,
    this.suggestion,
    this.dividerText,
    this.planAction,
  });

  factory _ChatItem.message({required String text, required bool isUser}) {
    return _ChatItem._(message: _ChatMessage(text: text, isUser: isUser));
  }

  factory _ChatItem.card({required _SuggestionCard suggestion}) {
    return _ChatItem._(suggestion: suggestion);
  }

  factory _ChatItem.divider({required String text}) {
    return _ChatItem._(dividerText: text);
  }

  factory _ChatItem.planAction({
    required String planId,
    required String label,
  }) {
    return _ChatItem._(planAction: _PlanAction(planId: planId, label: label));
  }

  final _ChatMessage? message;
  final _SuggestionCard? suggestion;
  final String? dividerText;
  final _PlanAction? planAction;

  bool get isCard => suggestion != null;
  bool get isMessage => message != null;
  bool get isDivider => dividerText != null;
  bool get isPlanAction => planAction != null;
}

class _PlanAction {
  const _PlanAction({required this.planId, required this.label});
  final String planId;
  final String label;
}

class _ChatMessage {
  _ChatMessage({required this.text, required this.isUser});
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
