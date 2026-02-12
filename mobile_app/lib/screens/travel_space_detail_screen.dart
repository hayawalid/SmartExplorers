import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

/// Detail page for a Travel Space / Group.
/// Shows the shared itinerary between group members and their interests.
class TravelSpaceDetailScreen extends StatefulWidget {
  final String spaceName;
  final int memberCount;
  final String image;
  final String tag;

  const TravelSpaceDetailScreen({
    Key? key,
    required this.spaceName,
    required this.memberCount,
    required this.image,
    required this.tag,
  }) : super(key: key);

  @override
  State<TravelSpaceDetailScreen> createState() =>
      _TravelSpaceDetailScreenState();
}

class _TravelSpaceDetailScreenState extends State<TravelSpaceDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _joined = false;

  // Sample members
  static const _members = [
    _Member(name: 'Jana G.', interest: 'History & Culture', avatar: 'J'),
    _Member(name: 'Ahmed M.', interest: 'Photography', avatar: 'A'),
    _Member(name: 'Sara K.', interest: 'Adventure Sports', avatar: 'S'),
    _Member(name: 'Omar H.', interest: 'Food & Cuisine', avatar: 'O'),
    _Member(name: 'Nour A.', interest: 'Art & Museums', avatar: 'N'),
  ];

  // Sample shared itinerary
  static const _sharedItinerary = [
    _SharedActivity(
      title: 'Pyramids of Giza',
      time: '09:00 AM – 12:00 PM',
      location: 'Giza, Cairo',
      day: 'Day 1',
      image: 'lib/public/pexels-meryemmeva-34823948.jpg',
    ),
    _SharedActivity(
      title: 'Egyptian Museum Tour',
      time: '02:00 PM – 05:00 PM',
      location: 'Tahrir Square, Cairo',
      day: 'Day 1',
      image: 'lib/public/smart_itineraries.jpg',
    ),
    _SharedActivity(
      title: 'Khan El Khalili Market',
      time: '10:00 AM – 01:00 PM',
      location: 'Islamic Cairo',
      day: 'Day 2',
      image: 'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
    ),
    _SharedActivity(
      title: 'Nile Dinner Cruise',
      time: '07:00 PM – 10:00 PM',
      location: 'Nile Corniche',
      day: 'Day 2',
      image: 'lib/public/verified_guides.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
    final textColor = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = isDark ? Colors.white54 : AppDesign.midGrey;
    final card = isDark ? AppDesign.cardDark : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // Hero image header
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Background image
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Image.asset(widget.image, fit: BoxFit.cover),
                ),
                // Gradient overlay
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.3),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Title overlay
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesign.electricCobalt.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.tag,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.spaceName,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.memberCount} members',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Join / Leave button
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _joined = !_joined);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _joined
                              ? (isDark
                                  ? AppDesign.darkGrey
                                  : AppDesign.lightGrey)
                              : AppDesign.electricCobalt,
                      foregroundColor:
                          _joined
                              ? (isDark ? Colors.white70 : AppDesign.midGrey)
                              : Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _joined ? 'Leave Group' : 'Join Group',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Members section
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Members & Interests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._members.map(
                      (m) => _buildMemberTile(m, isDark, card, textColor, sub),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Shared Itinerary section
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Text(
                  'Shared Itinerary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),

          // Itinerary activity cards
          SliverList(
            delegate: SliverChildBuilderDelegate((context, i) {
              final activity = _sharedItinerary[i];
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _SharedActivityCard(
                    activity: activity,
                    isDark: isDark,
                  ),
                ),
              );
            }, childCount: _sharedItinerary.length),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(
    _Member member,
    bool isDark,
    Color card,
    Color textColor,
    Color sub,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? [] : AppDesign.softShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppDesign.electricCobalt.withOpacity(0.12),
            child: Text(
              member.avatar,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppDesign.electricCobalt,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(LucideIcons.sparkles, size: 12, color: sub),
                    const SizedBox(width: 4),
                    Text(
                      member.interest,
                      style: TextStyle(fontSize: 12, color: sub),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(LucideIcons.messageCircle, size: 18, color: sub),
        ],
      ),
    );
  }
}

/// Expandable shared activity card with image background
class _SharedActivityCard extends StatefulWidget {
  final _SharedActivity activity;
  final bool isDark;

  const _SharedActivityCard({required this.activity, required this.isDark});

  @override
  State<_SharedActivityCard> createState() => _SharedActivityCardState();
}

class _SharedActivityCardState extends State<_SharedActivityCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        height: _expanded ? 260 : 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              widget.isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(widget.activity.image, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Day badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.activity.day,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.activity.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.clock,
                          size: 13,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.activity.time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    // Expanded content
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.activity.location,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Attendees row
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.users,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '5 members attending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                                const Spacer(),
                                // Mini avatar stack
                                SizedBox(
                                  width: 80,
                                  height: 24,
                                  child: Stack(
                                    children: List.generate(
                                      3,
                                      (i) => Positioned(
                                        left: i * 18.0,
                                        child: CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.white
                                              .withOpacity(0.9),
                                          child: Text(
                                            ['J', 'A', 'S'][i],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: AppDesign.eerieBlack,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      crossFadeState:
                          _expanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
              // Expand indicator
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedRotation(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Member {
  const _Member({
    required this.name,
    required this.interest,
    required this.avatar,
  });
  final String name;
  final String interest;
  final String avatar;
}

class _SharedActivity {
  const _SharedActivity({
    required this.title,
    required this.time,
    required this.location,
    required this.day,
    required this.image,
  });
  final String title;
  final String time;
  final String location;
  final String day;
  final String image;
}
