import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../services/session_store.dart';
import '../services/social_api_service.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final SocialApiService _socialService = SocialApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _submitting = false;
  String? _selectedImage;

  static const List<String> _suggestedImages = [
    'lib/public/pexels-meryemmeva-34823948.jpg',
    'lib/public/smart_itineraries.jpg',
    'lib/public/pexels-zahide-tas-367420941-28406392.jpg',
    'lib/public/verified_guides.jpg',
  ];

  @override
  void dispose() {
    _socialService.dispose();
    _captionController.dispose();
    _imageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _publishPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final caption = _captionController.text.trim();
    final image =
        _imageController.text.trim().isNotEmpty
            ? _imageController.text.trim()
            : _selectedImage;
    final authorId = SessionStore.instance.userId;
    final authorName = SessionStore.instance.username ?? 'Traveler';

    setState(() => _submitting = true);

    try {
      await _socialService.createPost(
        {
          if (authorId != null) 'author_id': authorId,
          'author_name': authorName,
          'author_username': SessionStore.instance.username ?? authorName,
          'caption': caption,
          'text': caption,
          'media_url': image,
          'location': _locationController.text.trim(),
          'like_count': 0,
          'comment_count': 0,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'source': 'mobile_app',
        }..removeWhere((key, value) => value == null || value == ''),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Post published'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish post: $error'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? AppDesign.eerieBlack : AppDesign.offWhite;
    final card = isDark ? AppDesign.cardDark : Colors.white;
    final text = isDark ? Colors.white : AppDesign.eerieBlack;
    final sub = AppDesign.midGrey;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Post'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _submitting ? null : _publishPost,
              child:
                  _submitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Publish'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors:
                        isDark
                            ? [
                              Colors.white.withValues(alpha: 0.07),
                              Colors.white.withValues(alpha: 0.03),
                            ]
                            : [Colors.white, AppDesign.offWhite],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppDesign.lightGrey,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share a moment from the road',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Post a story, tip, or travel highlight for the community.',
                      style: TextStyle(fontSize: 13, color: sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Caption',
                icon: LucideIcons.pen_line,
                isDark: isDark,
                child: TextFormField(
                  controller: _captionController,
                  minLines: 5,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'What are you sharing today?',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Add a caption before posting';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Photo',
                icon: LucideIcons.image,
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _imageController,
                      decoration: const InputDecoration(
                        hintText: 'Image asset path or URL (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final image = _suggestedImages[index];
                          final selected = _selectedImage == image;
                          return ChoiceChip(
                            label: Text('Image ${index + 1}'),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _selectedImage = image;
                                _imageController.text = image;
                              });
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemCount: _suggestedImages.length,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Location',
                icon: LucideIcons.map_pin,
                isDark: isDark,
                child: TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    hintText: 'Where was this taken? (optional)',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color:
                      isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white,
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : AppDesign.lightGrey,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppDesign.electricCobalt.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        color: AppDesign.electricCobalt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your post will appear in the feed immediately after publishing.',
                        style: TextStyle(color: sub, height: 1.4),
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
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.isDark,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? AppDesign.cardDark : Colors.white,
        border: Border.all(
          color:
              isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppDesign.lightGrey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppDesign.electricCobalt),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppDesign.eerieBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
