import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../services/session_store.dart';
import '../services/social_api_service.dart';
import '../theme/app_theme.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, this.providerName, this.providerId});

  final String? providerName;
  final String? providerId;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final SocialApiService _socialService = SocialApiService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _providerController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 5.0;
  bool _submitting = false;

  static const List<String> _quickRatings = [
    'Excellent',
    'Great',
    'Good',
    'Fair',
  ];

  @override
  void initState() {
    super.initState();
    _providerController.text = widget.providerName ?? '';
  }

  @override
  void dispose() {
    _socialService.dispose();
    _providerController.dispose();
    _locationController.dispose();
    _titleController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authorId = SessionStore.instance.userId;
    final authorName = SessionStore.instance.username ?? 'Traveler';
    final providerName = _providerController.text.trim();

    setState(() => _submitting = true);

    try {
      await _socialService.createReview(
        {
          if (authorId != null) 'author_id': authorId,
          'author_username': SessionStore.instance.username ?? authorName,
          'author_name': authorName,
          if (widget.providerId != null && widget.providerId!.isNotEmpty)
            'provider_id': widget.providerId,
          'provider_name': providerName,
          'title': _titleController.text.trim(),
          'content': _reviewController.text.trim(),
          'text': _reviewController.text.trim(),
          'location': _locationController.text.trim(),
          'rating': _rating,
          'helpful': 0,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'source': 'mobile_app',
        }..removeWhere((key, value) => value == null || value == ''),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Review submitted'),
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
          content: Text('Failed to submit review: $error'),
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
        title: const Text('Write Review'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _submitting ? null : _submitReview,
              child:
                  _submitting
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Submit'),
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
                      'Share what the experience was really like',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your review helps other travelers choose confidently.',
                      style: TextStyle(fontSize: 13, color: sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'Provider',
                icon: LucideIcons.user_round,
                isDark: isDark,
                child: TextFormField(
                  controller: _providerController,
                  decoration: const InputDecoration(
                    hintText: 'Provider or guide name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Add a provider name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Rating',
                icon: LucideIcons.star,
                isDark: isDark,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final active = index < _rating.round();
                          return IconButton(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _rating = (index + 1).toDouble();
                              });
                            },
                            icon: Icon(
                              active ? LucideIcons.star : LucideIcons.star,
                              color:
                                  active
                                      ? const Color(0xFFFFC107)
                                      : AppDesign.midGrey,
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _rating.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: text,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap a star to set the score.',
                      style: TextStyle(fontSize: 12, color: sub),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Review title',
                icon: LucideIcons.pen_line,
                isDark: isDark,
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'A short summary of your experience',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Add a short title';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Review',
                icon: LucideIcons.message_square_more,
                isDark: isDark,
                child: TextFormField(
                  controller: _reviewController,
                  minLines: 5,
                  maxLines: 8,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText:
                        'Describe what stood out, what to expect, and any tips...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Write the review text';
                    }
                    return null;
                  },
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
                    hintText: 'Where did this happen? (optional)',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick tone',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children:
                          _quickRatings
                              .map(
                                (label) => ChoiceChip(
                                  label: Text(label),
                                  selected: false,
                                  onSelected: (_) {},
                                ),
                              )
                              .toList(),
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
