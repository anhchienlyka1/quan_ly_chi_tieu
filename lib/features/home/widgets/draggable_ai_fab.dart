import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/context_extensions.dart';

/// A draggable floating AI assistant button that can be moved freely
/// across the screen. Displays a premium sparkle icon with glow animation.
///
/// Performance-optimised: uses a single AnimationController for glow/float,
/// wraps the heavy paint in [RepaintBoundary], and avoids unnecessary
/// setState calls by using AnimatedBuilder scoped to only the paint subtree.
class DraggableAiFab extends StatefulWidget {
  final VoidCallback onTap;
  final bool showAlertDot;

  const DraggableAiFab({
    super.key,
    required this.onTap,
    this.showAlertDot = false,
  });

  @override
  State<DraggableAiFab> createState() => _DraggableAiFabState();
}

class _DraggableAiFabState extends State<DraggableAiFab>
    with SingleTickerProviderStateMixin {
  // Position state
  double _xPos = -1; // -1 means not initialized
  double _yPos = -1;
  bool _isDragging = false;
  bool _isInitialized = false;

  // Single animation controller drives both glow & float
  late AnimationController _animController;

  // Snap animation (driven manually via Tween)
  double _snapStartX = 0;
  double _snapStartY = 0;
  double _snapEndX = 0;
  double _snapEndY = 0;
  bool _isSnapping = false;
  double _snapT = 1.0; // 0..1

  static const double _fabSize = 56.0;
  static const double _edgePadding = 16.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(); // single forward loop → cheaper than two independent repeats
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _initPosition(BuildContext context) {
    if (_isInitialized) return;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    // Default position: bottom-right corner
    _xPos = size.width - _fabSize - _edgePadding;
    _yPos = size.height - _fabSize - padding.bottom - 100;
    _isInitialized = true;
  }

  void _snapToEdge(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final centerX = _xPos + _fabSize / 2;

    _snapStartX = _xPos;
    _snapStartY = _yPos;

    if (centerX < size.width / 2) {
      _snapEndX = _edgePadding;
    } else {
      _snapEndX = size.width - _fabSize - _edgePadding;
    }

    final padding = MediaQuery.of(context).padding;
    _snapEndY = _yPos.clamp(
      padding.top + _edgePadding,
      size.height - _fabSize - padding.bottom - 80,
    );

    _isSnapping = true;
    _snapT = 0.0;
    // Drive snap by the already-running controller listener
    _animController.addListener(_snapTick);
  }

  void _snapTick() {
    if (!_isSnapping) {
      _animController.removeListener(_snapTick);
      return;
    }
    // Advance snap by elapsed fraction (≈16ms per frame → 300ms total)
    _snapT += 1 / 18; // ~18 frames at 60fps ≈ 300ms
    if (_snapT >= 1.0) {
      _snapT = 1.0;
      _isSnapping = false;
      _animController.removeListener(_snapTick);
    }
    final t = Curves.easeOutCubic.transform(_snapT);
    setState(() {
      _xPos = _snapStartX + (_snapEndX - _snapStartX) * t;
      _yPos = _snapStartY + (_snapEndY - _snapStartY) * t;
    });
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
          _isSnapping = false;
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
        child: RepaintBoundary(
          child: AnimatedScale(
            scale: _isDragging ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                final t = _animController.value; // 0→1 over 3s
                // Glow uses a ping-pong curve
                final glowValue = (sin(t * pi * 2) * 0.5 + 0.5);
                // Float uses a slower sine
                final floatOffset =
                    _isDragging ? 0.0 : sin(t * pi * 2) * 3;

                return Transform.translate(
                  offset: Offset(0, floatOffset),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildFab(context, glowValue),
                      if (widget.showAlertDot) _buildAlertDot(),
                    ],
                  ),
                );
              },
            ),
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

  Widget _buildAlertDot() {
    return Positioned(
      right: 0,
      top: 0,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.5),
              blurRadius: 6,
            ),
          ],
        ),
      ),
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
          BoxShadow(
            color: AppColors.aiGlow.withOpacity(0.25 + glowValue * 0.2),
            blurRadius: 16 + glowValue * 8,
            spreadRadius: 1 + glowValue * 2,
          ),
          BoxShadow(
            color: AppColors.aiAccent.withOpacity(0.1 + glowValue * 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
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
          const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 28,
          ),
          // 2 orbiting sparkles (reduced from 4) — computed in the
          // AnimatedBuilder callback so no extra setState.
          ...List.generate(2, (i) {
            final angle = (i * pi) + (glowValue * pi * 0.5);
            const radius = 20.0;
            final sparkleOpacity =
                (0.4 + sin(glowValue * pi * 2 + i * 1.5) * 0.4)
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
