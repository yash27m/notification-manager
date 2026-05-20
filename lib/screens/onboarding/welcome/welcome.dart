import 'package:flutter/material.dart';
import 'welcome_controller.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final _controller = WelcomeController();

  // --- Theme Colors ---
  static const _primary = Color(0xFF2AAEA1);
  static const _gradientEnd = Color(0xFF2FC0B1);
  static const _accent = Color(0xFFDBEEEB);
  static const _support = Color(0xFFFCFEFF);

  @override
  void initState() {
    super.initState();
    _controller.init(this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _support,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // --- Marquee Icons ---
            _buildMarqueeIcons(),

            const SizedBox(height: 48),

            // --- Title ---
            const Text(
              'Manage all your\nnotifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: Color(0xFF1A1A2E),
              ),
            ),

            const SizedBox(height: 20),

            // --- Description ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                    height: 1.6,
                  ),
                  children: [
                    const TextSpan(
                      text: 'Notification Reader',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const TextSpan(
                      text:
                          ' is a backup app designed to provide backup services for your notifications and storage.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'By using this app, you accept that it may be incompatible with the Terms of Use of other apps on your device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(flex: 3),

            // --- Accept Button ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () =>  _controller.acceptClicked(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Terms & Conditions ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'By continuing, you accept our ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Open T&C
                  },
                  child: const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 13,
                      color: _primary,
                      decoration: TextDecoration.underline,
                      decorationColor: _primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMarqueeIcons() {
    const marqueeWidth = 300.0;
    const marqueeHeight = 100.0;
    const iconSize = 82.5;

    return SizedBox(
      width: marqueeWidth,
      height: marqueeHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Random organic light glow blobs
          Positioned(
            left: 40,
            top: -25,
            child: _glowBlob(150, 100, 0.12),
          ),
          Positioned(
            left: 100,
            top: -15,
            child: _glowBlob(110, 90, 0.08),
          ),
          Positioned(
            left: 60,
            top: 10,
            child: _glowBlob(160, 70, 0.06),
          ),

          // Animated marquee icons
          AnimatedBuilder(
            animation: _controller.rotationAnimation,
            builder: (context, _) {
              final icons = _controller.getMarqueeIcons(
                _controller.rotationAnimation.value,
              );

              return Stack(
                children: icons.map((item) {
                  final cx = marqueeWidth / 2;
                  final cy = marqueeHeight / 2;

                  final scaledSize = iconSize * item.scale;
                  final dx = cx + item.x * (marqueeWidth * 0.38) - scaledSize / 2;
                  final dy = cy + item.y * marqueeHeight - scaledSize / 2;

                  return Positioned(
                    left: dx,
                    top: dy,
                    child: Opacity(
                      opacity: item.opacity,
                      child: Transform.scale(
                        scale: item.scale,
                        child: _buildIconBubble(item.assetPath, iconSize),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double width, double height, double opacity) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: _accent.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildIconBubble(String assetPath, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: _accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Image.asset(
        assetPath,
        errorBuilder: (_, __, ___) => Icon(
          Icons.notifications_outlined,
          color: _primary,
          size: size * 0.4,
        ),
      ),
    );
  }
}