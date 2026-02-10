import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';

class SafetyDashboardScreen extends StatefulWidget {
  const SafetyDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SafetyDashboardScreen> createState() => _SafetyDashboardScreenState();
}

class _SafetyDashboardScreenState extends State<SafetyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isTracking = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),

              const SizedBox(height: 30),

              // Status card
              _buildStatusCard(),

              const SizedBox(height: 24),

              // Panic button
              _buildPanicButton(),

              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActions(),

              const SizedBox(height: 24),

              // Emergency contacts
              _buildEmergencyContacts(),

              const SizedBox(height: 24),

              // Safety tips
              _buildSafetyTips(),

              // Bottom padding for nav bar
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety Dashboard',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'SF Pro Display',
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your safety is our priority',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
          ),
          child: Icon(
            CupertinoIcons.settings,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF4CAF50).withOpacity(0.3),
                const Color(0xFF45a049).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF4CAF50).withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF4CAF50,
                          ).withOpacity(0.3 + (_pulseController.value * 0.2)),
                        ),
                        child: const Icon(
                          CupertinoIcons.shield_fill,
                          color: Color(0xFF4CAF50),
                          size: 30,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'All Systems Active',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GPS tracking enabled • Location shared',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            fontFamily: 'SF Pro Text',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Tracking',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                  CupertinoSwitch(
                    value: _isTracking,
                    onChanged: (value) => setState(() => _isTracking = value),
                    activeColor: const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanicButton() {
    return GestureDetector(
      onLongPress: () {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Emergency Alert'),
                content: const Text(
                  'Are you sure you want to send an emergency alert? This will notify your emergency contacts and local authorities.',
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    child: const Text('Send Alert'),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Emergency alert sent!')),
                      );
                    },
                  ),
                ],
              ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFf5576c), Color(0xFFf093fb)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFf5576c).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 12),
            const Text(
              'PANIC BUTTON',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'SF Pro Display',
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Long press for emergency',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontFamily: 'SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': CupertinoIcons.phone_fill,
        'label': 'Call 122',
        'color': Color(0xFF667eea),
      },
      {
        'icon': CupertinoIcons.location_fill,
        'label': 'Share Location',
        'color': Color(0xFF4facfe),
      },
      {
        'icon': CupertinoIcons.person_2_fill,
        'label': 'Contacts',
        'color': Color(0xFFD4AF37),
      },
    ];

    return Row(
      children:
          actions.map((action) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
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
                      child: Column(
                        children: [
                          Icon(
                            action['icon'] as IconData,
                            color: action['color'] as Color,
                            size: 28,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            action['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                              fontFamily: 'SF Pro Text',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildEmergencyContacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 16),
        _buildContactCard('Mom', '+20 100 123 4567', '👩'),
        const SizedBox(height: 12),
        _buildContactCard('Embassy', '+20 2 2797 3300', '🏛️'),
        const SizedBox(height: 12),
        _buildAddContactButton(),
      ],
    );
  }

  Widget _buildContactCard(String name, String phone, String emoji) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.6),
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
                child: const Icon(
                  CupertinoIcons.phone_fill,
                  color: Color(0xFF4CAF50),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddContactButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.plus_circle_fill,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Add Emergency Contact',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
              fontFamily: 'SF Pro Text',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTips() {
    final tips = [
      'Always share your location with trusted contacts',
      'Keep your phone charged above 20%',
      'Store offline maps for emergencies',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Safety Tips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'SF Pro Display',
          ),
        ),
        const SizedBox(height: 16),
        ...tips.map(
          (tip) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.lightbulb_fill,
                  color: Color(0xFFD4AF37),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontFamily: 'SF Pro Text',
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
