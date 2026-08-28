import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum SnackTone { neutral, success, danger }

/// One way to talk back to the user.
///
/// Every page used to hand-roll `ScaffoldMessenger.showSnackBar`, so tone,
/// shape and duration drifted per screen. This collapses that into a single
/// call, drops any snack already on screen (so a fast tapper does not queue up
/// four of them) and adds a matching icon and haptic.
void showAppSnack(
  BuildContext context,
  String message, {
  SnackTone tone = SnackTone.neutral,
  SnackBarAction? action,
}) {
  Color background = AppColors.ink;
  IconData icon = Icons.info_outline;

  if (tone == SnackTone.success) {
    background = AppColors.success;
    icon = Icons.check_circle_outline;
    HapticFeedback.lightImpact();
  } else if (tone == SnackTone.danger) {
    background = AppColors.danger;
    icon = Icons.error_outline;
    HapticFeedback.heavyImpact();
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: background,
      duration: const Duration(seconds: 3),
      action: action,
      content: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: Gap.md),
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

/// A docked bar that keeps the primary action reachable with one thumb.
///
/// Upwork never buries "Submit a proposal" at the bottom of a long scroll; it
/// pins it. Pass a [secondary] widget to show context (a price, a deadline)
/// beside the button.
class AppActionBar extends StatelessWidget {
  const AppActionBar({super.key, required this.child, this.secondary});

  final Widget child;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
          child: secondary == null
              ? child
              : Row(
                  children: [
                    Expanded(child: secondary!),
                    const SizedBox(width: Gap.md),
                    Flexible(flex: 2, child: child),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Wraps a tappable surface so it dips slightly under the finger.
///
/// A card that visibly responds within a frame feels faster than one that
/// waits for the next route to build.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: AppDuration.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Scales its child while a finger is down, without swallowing the gesture.
///
/// Unlike [Pressable] this uses a [Listener], so an [InkWell] underneath still
/// gets its ripple and its onTap. Wrap cards with it for depth on touch.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.985 : 1,
        duration: AppDuration.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A pill that carries a status without shouting: tinted background, no border.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.tint,
    this.icon,
  });

  final String label;
  final Color color;
  final Color tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 5),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: Gap.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
