// import 'dart:math';
// import 'package:flutter/material.dart';

// class WelcomeController {
//   late final AnimationController animationController;
//   late final Animation<double> rotationAnimation;

//   /// Social media icon data
//   final List<SocialIcon> socialIcons = [
//     SocialIcon(label: 'WhatsApp', color: Color(0xFF25D366), icon: Icons.chat),
//     SocialIcon(label: 'Instagram', color: Color(0xFFE1306C), icon: Icons.camera_alt),
//     SocialIcon(label: 'YouTube', color: Color(0xFFFF0000), icon: Icons.play_arrow),
//     SocialIcon(label: 'Facebook', color: Color(0xFF1877F2), icon: Icons.facebook),
//     SocialIcon(label: 'TikTok', color: Color(0xFF000000), icon: Icons.music_note),
//   ];

//   void init(TickerProvider vsync) {
//     animationController = AnimationController(
//       vsync: vsync,
//       duration: const Duration(seconds: 10),
//     )..repeat();

//     rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
//       animationController,
//     );
//   }

//   /// Returns positioned icon data for each social icon on an elliptical orbit.
//   List<OrbitingIcon> getOrbitingIcons(double angle) {
//     final count = socialIcons.length;
//     final icons = <OrbitingIcon>[];

//     for (int i = 0; i < count; i++) {
//       final itemAngle = angle + (2 * pi * i / count);

//       // Ellipse: wider horizontally, shorter vertically
//       final x = cos(itemAngle);
//       final y = sin(itemAngle) * 0.35; // flatten the ellipse

//       // Depth for 3D effect (-1 back, +1 front)
//       final depth = sin(itemAngle);

//       // Scale: bigger in front, smaller in back
//       final scale = 0.6 + 0.4 * ((depth + 1) / 2); // 0.6 to 1.0

//       // Opacity: fade at back
//       final opacity = (0.4 + 0.6 * ((depth + 1) / 2)).clamp(0.0, 1.0);

//       icons.add(OrbitingIcon(
//         social: socialIcons[i],
//         x: x,
//         y: y,
//         scale: scale,
//         opacity: opacity,
//         depth: depth,
//       ));
//     }

//     // Sort by depth so back icons render first (painter's algorithm)
//     icons.sort((a, b) => a.depth.compareTo(b.depth));
//     return icons;
//   }

//   void dispose() {
//     animationController.dispose();
//   }
// }

// class SocialIcon {
//   final String label;
//   final Color color;
//   final IconData icon;

//   const SocialIcon({
//     required this.label,
//     required this.color,
//     required this.icon,
//   });
// }

// class OrbitingIcon {
//   final SocialIcon social;
//   final double x;
//   final double y;
//   final double scale;
//   final double opacity;
//   final double depth;

//   const OrbitingIcon({
//     required this.social,
//     required this.x,
//     required this.y,
//     required this.scale,
//     required this.opacity,
//     required this.depth,
//   });
// }
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:notification_manager/screens/onboarding/choose_apps/choose_apps_screen.dart';

class WelcomeController {
  late final AnimationController animationController;
  late final Animation<double> rotationAnimation;

  /// Icon asset paths — replace with actual PNGs
  final List<String> iconPaths = [
    'assets/icons/whatsapp.png',
    'assets/icons/instagram.png',
    'assets/icons/youtube.png',
    'assets/icons/facebook.png',
    'assets/icons/snapchat.png',
  ];

  void init(TickerProvider vsync) {
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 8),
    )..repeat();

    rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(animationController);
  }

  /// Positions icons on a horizontal elliptical marquee path.
  List<MarqueeIcon> getMarqueeIcons(double angle) {
    final count = iconPaths.length;
    final icons = <MarqueeIcon>[];

    for (int i = 0; i < count; i++) {
      final itemAngle = angle + (2 * pi * i / count);

      // Wide horizontal ellipse, minimal vertical wobble
      final x = cos(itemAngle);
      final y = sin(itemAngle) * 0.08;

      // Depth for 3D effect
      final depth = sin(itemAngle);

      // Scale: 1.0 front center → 0.55 back
      final scale = 0.55 + 0.45 * ((depth + 1) / 2);

      // Opacity: 1.0 front → 0.3 back
      final opacity = (0.3 + 0.7 * ((depth + 1) / 2)).clamp(0.0, 1.0);

      icons.add(
        MarqueeIcon(
          assetPath: iconPaths[i],
          x: x,
          y: y,
          scale: scale,
          opacity: opacity,
          depth: depth,
        ),
      );
    }

    // Back icons render first
    icons.sort((a, b) => a.depth.compareTo(b.depth));
    return icons;
  }

  Future<void> acceptClicked(BuildContext context) async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChooseAppsScreen()),
    );
  }

  void dispose() {
    animationController.dispose();
  }
}

class MarqueeIcon {
  final String assetPath;
  final double x;
  final double y;
  final double scale;
  final double opacity;
  final double depth;

  const MarqueeIcon({
    required this.assetPath,
    required this.x,
    required this.y,
    required this.scale,
    required this.opacity,
    required this.depth,
  });
}
