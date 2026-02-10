import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium button component with loading state, scale animation, and haptic feedback.
/// Follows UI/UX Pro Max standards.
class ProButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final Color? backgroundColor;

  const ProButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.backgroundColor,
  });

  @override
  State<ProButton> createState() => _ProButtonState();
}

class _ProButtonState extends State<ProButton> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonChild = widget.isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(widget.label),
            ],
          );

    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: widget.onPressed != null ? _onTapCancel : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SizedBox(
          width: widget.width,
          child: widget.isOutlined
              ? OutlinedButton(
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.onPressed?.call();
                        },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: buttonChild,
                )
              : FilledButton(
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.onPressed?.call();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.backgroundColor,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: buttonChild,
                ),
        ),
      ),
    );
  }
}
