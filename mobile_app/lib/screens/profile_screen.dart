import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header / Profile card
              _buildProfileHeader(),

              const SizedBox(height: 24),

              // Stats
              _buildStats(),

              const SizedBox(height: 24),

              // Menu items
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildMenuSection('Account', [
                      MenuItem(
                        icon: CupertinoIcons.person_fill,
                        label: 'Edit Profile',
                        color: Color(0xFF667eea),
                      ),
                      MenuItem(
                        icon: CupertinoIcons.creditcard_fill,
                        label: 'Payment Methods',
                        color: Color(0xFF4facfe),
                      ),
                      MenuItem(
                        icon: CupertinoIcons.bell_fill,
                        label: 'Notifications',
                        color: Color(0xFFf093fb),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildMenuSection('Trips', [
                      MenuItem(
                        icon: CupertinoIcons.bookmark_fill,
                        label: 'Saved Places',
                        color: Color(0xFFD4AF37),
                      ),
                      MenuItem(
                        icon: CupertinoIcons.clock_fill,
                        label: 'Trip History',
                        color: Color(0xFF4CAF50),
                      ),
                      MenuItem(
                        icon: CupertinoIcons.star_fill,
                        label: 'Reviews',
                        color: Color(0xFFf5576c),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    _buildMenuSection('Support', [
                      MenuItem(
                        icon: CupertinoIcons.question_circle_fill,
                        label: 'Help Center',
                        color: Color(0xFF667eea),
                      ),
                      MenuItem(
                        icon: CupertinoIcons.doc_text_fill,
                        label: 'Terms & Privacy',
                        color: Color(0xFF9E9E9E),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // Log out button
                    _buildLogoutButton(),
                  ],
                ),
              ),

              // Bottom padding for nav bar
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text('👤', style: TextStyle(fontSize: 50)),
            ),
          ),

          const SizedBox(height: 16),

          // Name
          const Text(
            'Sarah Johnson',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'SF Pro Display',
            ),
          ),

          const SizedBox(height: 4),

          // Email
          Text(
            'sarah.johnson@email.com',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'SF Pro Text',
            ),
          ),

          const SizedBox(height: 16),

          // Verified badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              border: Border.all(
                color: const Color(0xFF4CAF50).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  size: 16,
                  color: Color(0xFF4CAF50),
                ),
                SizedBox(width: 6),
                Text(
                  'Verified Traveler',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4CAF50),
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('12', 'Trips'),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildStatItem('8', 'Reviews'),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildStatItem('4.9', 'Rating'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
            fontFamily: 'SF Pro Text',
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(String title, List<MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.5),
            fontFamily: 'SF Pro Text',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children:
                    items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Column(
                        children: [
                          _buildMenuItem(item),
                          if (index < items.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Divider(
                                color: Colors.white.withOpacity(0.1),
                                height: 1,
                              ),
                            ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: item.color.withOpacity(0.2),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            color: Colors.white.withOpacity(0.4),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFf5576c).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFf5576c).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // Handle logout
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        CupertinoIcons.square_arrow_left,
                        color: Color(0xFFf5576c),
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFf5576c),
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MenuItem {
  final IconData icon;
  final String label;
  final Color color;

  MenuItem({required this.icon, required this.label, required this.color});
}
