import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'dart:async';
import '../theme/app_theme.dart';

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

  // Sample prompt chips
  static const _samplePrompts = [
    'Plan a 3-day Tokyo trip',
    'Weekend getaway near me',
    'Food tour in Italy',
    'Budget trip under \$500',
    'Family-friendly activities',
    'Romantic destinations',
  ];

  @override
  void initState() {
    super.initState();
    _chatItems.add(
      _ChatItem.message(
        text: 'Hello! 🌍 I\'m your AI travel assistant. '
            'Tell me where you\'d like to go, and I\'ll create the perfect itinerary for you.',
        isUser: false,
      ),
    );
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

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      
      final lowerText = text.toLowerCase();
      final isItineraryRequest = lowerText.contains('plan') ||
          lowerText.contains('trip') ||
          lowerText.contains('itinerary') ||
          lowerText.contains('tokyo') ||
          lowerText.contains('travel') ||
          lowerText.contains('day');

      setState(() {
        _isTyping = false;
        
        if (isItineraryRequest) {
          // Add text message
          _chatItems.add(
            _ChatItem.message(
              text: 'I\'d love to help you plan an amazing 3-day Tokyo adventure! '
                  'Here\'s a curated itinerary based on the best experiences:',
              isUser: false,
            ),
          );
          
          // Add divider with "Planner" text
          _chatItems.add(_ChatItem.divider(text: 'Planner'));
          
          // Add suggestion cards inline (no buttons on cards)
          _chatItems.add(
            _ChatItem.card(
              suggestion: _SuggestionCard(
                id: '1',
                title: 'Park Hyatt Tokyo',
                subtitle: 'Suggested Hotel',
                location: 'Shinjuku, Tokyo',
                price: '\$120',
                priceUnit: '/ per Night',
                rating: 4.8,
                imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400',
                amenities: ['2 Beds', 'Dinner', '2 Guest', 'Dinner'],
                type: 'hotel',
              ),
            ),
          );
          
          _chatItems.add(
            _ChatItem.card(
              suggestion: _SuggestionCard(
                id: '2',
                title: 'Senso-ji Temple',
                subtitle: 'Must-Visit Attraction',
                location: 'Asakusa, Tokyo',
                price: 'Free',
                priceUnit: '',
                rating: 4.9,
                imageUrl: 'https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400',
                amenities: ['Historic', 'Photos', 'Gardens'],
                type: 'attraction',
              ),
            ),
          );
          
          _chatItems.add(
            _ChatItem.card(
              suggestion: _SuggestionCard(
                id: '3',
                title: 'Sukiyabashi Jiro',
                subtitle: 'Top Restaurant',
                location: 'Ginza, Tokyo',
                price: '\$300',
                priceUnit: '/ person',
                rating: 4.7,
                imageUrl: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=400',
                amenities: ['Sushi', '2 Guest', 'Dinner'],
                type: 'restaurant',
              ),
            ),
          );
          
          // Add plan action button after all cards
          _chatItems.add(
            _ChatItem.planAction(
              planId: 'tokyo_day1',
              label: 'Apply this plan to your itinerary',
            ),
          );
        } else {
          // Regular chat response
          _chatItems.add(
            _ChatItem.message(
              text: 'That\'s exciting! What experiences are you looking for? '
                  'Food, culture, nightlife, or a mix of everything?',
              isUser: false,
            ),
          );
        }
      });
      
      _scrollChat();
    });
  }

  void _applySuggestion(String id) {
    HapticFeedback.mediumImpact();
    
    // Find and update the card
    for (int i = 0; i < _chatItems.length; i++) {
      if (_chatItems[i].isCard && _chatItems[i].suggestion?.id == id) {
        setState(() {
          _chatItems[i] = _ChatItem.card(
            suggestion: _chatItems[i].suggestion!.copyWith(isSaved: true),
          );
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${_chatItems[i].suggestion!.title} added to your itinerary'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppDesign.electricCobalt,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      }
    }
  }

  void _applyPlan(String planId) {
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Plan applied to your itinerary'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppDesign.electricCobalt,
        duration: const Duration(seconds: 2),
      ),
    );
    
    // Update the plan action button to show as applied
    for (int i = 0; i < _chatItems.length; i++) {
      if (_chatItems[i].isPlanAction && _chatItems[i].planAction?.planId == planId) {
        setState(() {
          _chatItems[i] = _ChatItem.planAction(
            planId: planId,
            label: '✓ Plan applied',
          );
        });
        break;
      }
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
            backgroundColor: isApplied
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
                  color: isApplied
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
          CircleAvatar(
            radius: 20,
            backgroundColor: AppDesign.electricCobalt.withOpacity(0.2),
            child: Icon(
              LucideIcons.sparkles,
              color: AppDesign.electricCobalt,
              size: 20,
            ),
          ),
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
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
              itemBuilder: (_, i) => ActionChip(
                label: Text(
                  _samplePrompts[i],
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : AppDesign.eerieBlack,
                  ),
                ),
                backgroundColor: isDark ? AppDesign.darkGrey : AppDesign.offWhite,
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
          color: msg.isUser
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
            color: msg.isUser
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
      builder: (_, v, __) => Opacity(
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

// Suggestion Card Widget
class _SuggestionCardWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDesign.darkGrey : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              suggestion.subtitle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : AppDesign.midGrey,
              ),
            ),
          ),
          
          // Image with overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppDesign.electricCobalt.withOpacity(0.3),
                        AppDesign.electricCobalt.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    _getIconForType(suggestion.type),
                    size: 60,
                    color: AppDesign.electricCobalt.withOpacity(0.3),
                  ),
                ),
              ),
              
              // Bookmark button
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    suggestion.isSaved
                        ? LucideIcons.bookmark
                        : LucideIcons.bookmark,
                    size: 18,
                    color: suggestion.isSaved
                        ? AppDesign.electricCobalt
                        : AppDesign.midGrey,
                  ),
                ),
              ),
              
              // Rating badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        suggestion.rating.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppDesign.eerieBlack,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        suggestion.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppDesign.eerieBlack,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          suggestion.price,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppDesign.eerieBlack,
                          ),
                        ),
                        if (suggestion.priceUnit.isNotEmpty)
                          Text(
                            suggestion.priceUnit,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white54 : AppDesign.midGrey,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 14,
                      color: isDark ? Colors.white54 : AppDesign.midGrey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      suggestion.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : AppDesign.midGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Amenities
                Row(
                  children: [
                    for (int i = 0; i < suggestion.amenities.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(
                            width: 1,
                            height: 12,
                            color: isDark ? Colors.white10 : AppDesign.lightGrey,
                          ),
                        ),
                      Row(
                        children: [
                          Icon(
                            _getAmenityIcon(suggestion.amenities[i]),
                            size: 14,
                            color: isDark ? Colors.white54 : AppDesign.midGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            suggestion.amenities[i],
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : AppDesign.midGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action button (only show if enabled)
                if (showButton)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: suggestion.isSaved ? null : onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: suggestion.isSaved
                            ? (isDark ? AppDesign.darkGrey : AppDesign.lightGrey)
                            : const Color(0xFF1A1D3F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        suggestion.isSaved ? 'Saved to itinerary' : 'Save to itinerary',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: suggestion.isSaved
                              ? (isDark ? Colors.white38 : AppDesign.midGrey)
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'hotel':
        return LucideIcons.bed;
      case 'restaurant':
        return LucideIcons.utensils;
      case 'attraction':
        return LucideIcons.landmark;
      default:
        return LucideIcons.mapPin;
    }
  }

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

  _SuggestionCard copyWith({
    String? title,
    String? price,
    bool? isSaved,
  }) {
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

  factory _ChatItem.planAction({required String planId, required String label}) {
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