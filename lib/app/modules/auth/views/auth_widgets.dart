import 'package:flutter/material.dart';

// Shared Left Panel used by both LoginView and RegisterView
class AuthLeftPanel extends StatelessWidget {
  const AuthLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D2137), Color(0xFF061120)],
        ),
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Glow blobs
          Positioned(
            top: -80,
            left: -80,
            child: AuthGlowBlob(color: const Color(0xFF1565C0), size: 300),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: AuthGlowBlob(color: const Color(0xFF0288D1), size: 250),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand logo + name
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/main_logo.png',
                      width: 40,
                      height: 40,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Jronix',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Headline
                const Text(
                  'Test APIs\nFaster Than\nEver Before.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The modern API client built for\ndevelopers who move fast.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),

                // Feature pills
                const Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    AuthFeaturePill(icon: Icons.bolt, label: 'REST & GraphQL'),
                    AuthFeaturePill(icon: Icons.wifi, label: 'WebSocket'),
                    AuthFeaturePill(icon: Icons.sync_alt, label: 'Socket.IO'),
                    AuthFeaturePill(icon: Icons.people_outline, label: 'Team Workspaces'),
                  ],
                ),

                // Illustration — fills remaining space edge to edge
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Image.asset(
                      'assets/icons/login_screen_image.png',
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.bottomCenter,
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
}

class AuthGlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const AuthGlowBlob({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.25), Colors.transparent],
        ),
      ),
    );
  }
}

class AuthFeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const AuthFeaturePill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4FC3F7)),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Shared Glass Card used by both LoginView and RegisterView
class AuthGlassCard extends StatelessWidget {
  final Widget child;
  const AuthGlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            spreadRadius: -8,
          ),
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.15),
            blurRadius: 80,
            spreadRadius: -16,
          ),
        ],
      ),
      child: child,
    );
  }
}
