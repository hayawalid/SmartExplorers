import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

/// Instagram-style social feed with WCAG accessibility support
class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<FeedPost> _posts = [
    FeedPost(
      id: '1',
      username: 'sarah_adventures',
      userAvatar: '👩‍🦰',
      isVerified: true,
      location: 'Pyramids of Giza, Cairo',
      imageEmoji: '🏛️',
      caption:
          'Standing before 4,500 years of history. The Great Pyramid never fails to amaze! 🇪🇬✨ #Egypt #Pyramids #Travel',
      likes: 2847,
      comments: 156,
      timeAgo: '2 hours ago',
      altText:
          'Tourist standing in front of the Great Pyramid of Giza during golden hour',
      isPromotion: false,
    ),
    FeedPost(
      id: '2',
      username: 'nile_cruises_egypt',
      userAvatar: '🚢',
      isVerified: true,
      location: 'Luxor, Egypt',
      imageEmoji: '⛵',
      caption:
          '🌟 SPECIAL OFFER: 3-night Luxor to Aswan cruise with SmartExplorers verified guides! All-inclusive from \$499. Book through our app for 15% off! #NileCruise #EgyptTravel',
      likes: 1523,
      comments: 89,
      timeAgo: '5 hours ago',
      altText:
          'Luxury cruise ship sailing on the Nile River at sunset with temples visible in background',
      isPromotion: true,
    ),
    FeedPost(
      id: '3',
      username: 'ahmed_guide_',
      userAvatar: '👨‍🏫',
      isVerified: true,
      location: 'Valley of the Kings, Luxor',
      imageEmoji: '⚱️',
      caption:
          'Another wonderful day sharing the secrets of Tutankhamun\'s tomb with visitors from Japan! 🇯🇵 Love my job as a verified SmartExplorers guide. #Guide #History',
      likes: 967,
      comments: 45,
      timeAgo: '8 hours ago',
      altText:
          'Professional tour guide in Valley of the Kings explaining hieroglyphics to a group of tourists',
      isPromotion: false,
    ),
    FeedPost(
      id: '4',
      username: 'red_sea_diving',
      userAvatar: '🤿',
      isVerified: true,
      location: 'Sharm El Sheikh',
      imageEmoji: '🐠',
      caption:
          '🐠 Discover the underwater paradise of the Red Sea! Our certified diving instructors are SmartExplorers verified. First dive FREE for app users! #Diving #RedSea',
      likes: 2156,
      comments: 178,
      timeAgo: '1 day ago',
      altText:
          'Colorful coral reef with tropical fish in the Red Sea near Sharm El Sheikh',
      isPromotion: true,
    ),
  ];

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
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(child: _buildHeader(textColor)),

            // Stories row
            SliverToBoxAdapter(
              child: _buildStoriesRow(
                isDark,
                cardColor,
                textColor,
                secondaryTextColor,
              ),
            ),

            // Feed posts
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildFeedPost(
                  _posts[index],
                  isDark,
                  cardColor,
                  textColor,
                  secondaryTextColor,
                ),
                childCount: _posts.length,
              ),
            ),

            // Bottom padding for nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Semantics(
            header: true,
            child: Text(
              'Feed',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'SF Pro Display',
              ),
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Create new post',
            child: _buildIconButton(CupertinoIcons.plus_app, () {}, textColor),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: 'Direct messages',
            child: _buildIconButton(
              CupertinoIcons.paperplane,
              () {},
              textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, Color iconColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }

  Widget _buildStoriesRow(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final stories = [
      {'name': 'Add Story', 'emoji': '+', 'isAdd': true},
      {'name': 'Cairo Guide', 'emoji': '🏛️', 'isAdd': false},
      {'name': 'Luxor Tips', 'emoji': '⚱️', 'isAdd': false},
      {'name': 'Red Sea', 'emoji': '🏖️', 'isAdd': false},
      {'name': 'Food Tour', 'emoji': '🍽️', 'isAdd': false},
      {'name': 'Desert', 'emoji': '🐪', 'isAdd': false},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Semantics(
            button: true,
            label:
                story['isAdd'] == true
                    ? 'Add your story'
                    : 'View ${story['name']} story',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          story['isAdd'] == true
                              ? null
                              : const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFFf5576c)],
                              ),
                      color:
                          story['isAdd'] == true
                              ? (isDark
                                  ? Colors.white.withOpacity(0.2)
                                  : const Color(0xFFE5E5EA))
                              : null,
                      border: Border.all(
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.3)
                                : const Color(0xFFD1D1D6),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        story['emoji'] as String,
                        style: TextStyle(
                          fontSize: story['isAdd'] == true ? 28 : 32,
                          color:
                              story['isAdd'] == true ? textColor : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    story['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                      fontFamily: 'SF Pro Text',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedPost(
    FeedPost post,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Semantics(
      container: true,
      label:
          post.isPromotion
              ? 'Sponsored post from ${post.username}'
              : 'Post from ${post.username}',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // User avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFFf5576c)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        post.userAvatar,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.username,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                            if (post.isVerified) ...[
                              const SizedBox(width: 4),
                              Semantics(
                                label: 'Verified account',
                                child: const Icon(
                                  CupertinoIcons.checkmark_seal_fill,
                                  size: 16,
                                  color: Color(0xFF4facfe),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          post.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (post.isPromotion)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Sponsored',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Semantics(
                    button: true,
                    label: 'More options for this post',
                    child: IconButton(
                      icon: Icon(CupertinoIcons.ellipsis, color: textColor),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            // Post image
            Semantics(
              image: true,
              label: post.altText,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.3),
                      const Color(0xFFf5576c).withOpacity(0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    post.imageEmoji,
                    style: const TextStyle(fontSize: 120),
                  ),
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Like this post, ${post.likes} likes',
                    child: _buildActionButton(
                      CupertinoIcons.heart,
                      '${post.likes}',
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Semantics(
                    button: true,
                    label: 'Comment on this post, ${post.comments} comments',
                    child: _buildActionButton(
                      CupertinoIcons.chat_bubble,
                      '${post.comments}',
                      textColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Semantics(
                    button: true,
                    label: 'Share this post',
                    child: _buildActionButton(
                      CupertinoIcons.paperplane,
                      '',
                      textColor,
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Save this post',
                    child: Icon(
                      CupertinoIcons.bookmark,
                      color: textColor.withOpacity(0.9),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Caption
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: textColor,
                    fontFamily: 'SF Pro Text',
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(
                      text: '${post.username} ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: post.caption),
                  ],
                ),
              ),
            ),

            // Time ago
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                post.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: secondaryTextColor,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String count, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.withOpacity(0.9), size: 24),
        if (count.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            count,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class FeedPost {
  final String id;
  final String username;
  final String userAvatar;
  final bool isVerified;
  final String location;
  final String imageEmoji;
  final String caption;
  final int likes;
  final int comments;
  final String timeAgo;
  final String altText;
  final bool isPromotion;

  FeedPost({
    required this.id,
    required this.username,
    required this.userAvatar,
    required this.isVerified,
    required this.location,
    required this.imageEmoji,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.timeAgo,
    required this.altText,
    required this.isPromotion,
  });
}
