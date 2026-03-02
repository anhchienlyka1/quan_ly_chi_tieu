import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';

/// A draggable floating AI assistant button that can be moved freely
/// across the screen. Displays a premium sparkle icon with glow animation.
class DraggableAiFab extends StatefulWidget {
  final VoidCallback onTap;

  const DraggableAiFab({
    super.key,
    required this.onTap,
  });

  @override
  State<DraggableAiFab> createState() => _DraggableAiFabState();
}

class _DraggableAiFabState extends State<DraggableAiFab>
    with TickerProviderStateMixin {
  // Position state
  double _xPos = -1; // -1 means not initialized
  double _yPos = -1;
  bool _isDragging = false;
  bool _isInitialized = false;

  // Animation controllers
  late AnimationController _glowController;
  late AnimationController _idleController;
  late AnimationController _snapController;

  // Snap animation values
  double _snapStartX = 0;
  double _snapStartY = 0;
  double _snapEndX = 0;
  double _snapEndY = 0;

  static const double _fabSize = 56.0;
  static const double _edgePadding = 16.0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(_onSnapAnimation);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _idleController.dispose();
    _snapController.dispose();
    super.dispose();
  }

  void _initPosition(BuildContext context) {
    if (_isInitialized) return;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    // Default position: bottom-right corner
    _xPos = size.width - _fabSize - _edgePadding;
    _yPos = size.height - _fabSize - padding.bottom - 100; // Above bottom nav
    _isInitialized = true;
  }

  void _onSnapAnimation() {
    setState(() {
      final t = Curves.easeOutCubic.transform(_snapController.value);
      _xPos = _snapStartX + (_snapEndX - _snapStartX) * t;
      _yPos = _snapStartY + (_snapEndY - _snapStartY) * t;
    });
  }

  void _snapToEdge(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = _xPos + _fabSize / 2;

    _snapStartX = _xPos;
    _snapStartY = _yPos;

    // Snap to nearest horizontal edge
    if (centerX < size.width / 2) {
      _snapEndX = _edgePadding;
    } else {
      _snapEndX = size.width - _fabSize - _edgePadding;
    }

    // Clamp vertical position
    final padding = MediaQuery.of(context).padding;
    _snapEndY = _yPos.clamp(
      padding.top + _edgePadding,
      size.height - _fabSize - padding.bottom - 80,
    );

    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    _initPosition(context);

    return Positioned(
      left: _xPos,
      top: _yPos,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _isDragging = true);
          _snapController.stop();
          HapticFeedback.lightImpact();
        },
        onPanUpdate: (details) {
          setState(() {
            _xPos += details.delta.dx;
            _yPos += details.delta.dy;
          });
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          _snapToEdge(context);
          HapticFeedback.lightImpact();
        },
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _isDragging ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedBuilder(
            animation: Listenable.merge([_glowController, _idleController]),
            builder: (context, child) {
              final glowValue = _glowController.value;
              final idleValue = _idleController.value;
              final floatOffset = _isDragging ? 0.0 : sin(idleValue * pi * 2) * 3;

              return Transform.translate(
                offset: Offset(0, floatOffset),
                child: _buildFab(context, glowValue),
              );
            },
          ),
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.5, 0.5),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          )
          .fade(duration: 200.ms),
    );
  }

  Widget _buildFab(BuildContext context, double glowValue) {
    final isDark = context.isDarkMode;

    return Container(
      width: _fabSize,
      height: _fabSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6), Color(0xFF00D2D3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          // Primary glow
          BoxShadow(
            color: AppColors.aiGlow.withOpacity(0.25 + glowValue * 0.2),
            blurRadius: 16 + glowValue * 8,
            spreadRadius: 1 + glowValue * 2,
          ),
          // Accent glow
          BoxShadow(
            color: AppColors.aiAccent.withOpacity(0.1 + glowValue * 0.1),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          // Drop shadow
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main icon
          const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 28,
          ),
          // Orbiting sparkles
          ...List.generate(4, (i) {
            final angle = (i * (pi * 2 / 4)) +
                (glowValue * pi * 0.5); // Slow rotation
            final radius = 20.0;
            final sparkleOpacity =
                (0.4 + sin(glowValue * pi * 2 + i * 1.2) * 0.4)
                    .clamp(0.0, 1.0);
            return Positioned(
              left: _fabSize / 2 + cos(angle) * radius - 2,
              top: _fabSize / 2 + sin(angle) * radius - 2,
              child: Opacity(
                opacity: sparkleOpacity,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
