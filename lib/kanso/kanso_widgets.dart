import 'package:flutter/material.dart';

import 'kanso_metrics.dart';
import 'kanso_tokens.dart';

/// A quiet tonal surface. No shadows; depth comes from surface tone alone.
class KansoSurface extends StatelessWidget {
  const KansoSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.border = false,
    this.radius = KansoRadius.medium,
    this.color,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool border;
  final BorderRadius radius;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? k.surfaceElevated,
        borderRadius: radius,
        border: border ? Border.all(color: k.borderSubtle, width: 1) : null,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return surface;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: surface,
      ),
    );
  }
}

/// Icon button with a full 48px touch target and a tooltip.
class KansoIconButton extends StatelessWidget {
  const KansoIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.size = 22,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: KansoSpace.touch,
        height: KansoSpace.touch,
        child: IconButton(
          icon: Icon(icon, size: size),
          color: selected ? k.accentStrong : k.textSecondary,
          onPressed: onPressed,
          tooltip: '',
          constraints: const BoxConstraints(minWidth: KansoSpace.touch, minHeight: KansoSpace.touch),
        ),
      ),
    );
  }
}

/// Filled primary action. Uses the Kanso accent fill with canvas-colored text.
class KansoPrimaryButton extends StatelessWidget {
  const KansoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    final child = FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: k.accentPrimary,
        foregroundColor: k.background,
        disabledBackgroundColor: k.surfaceSunken,
        disabledForegroundColor: k.textMuted,
        minimumSize: const Size(0, KansoSpace.touch),
        shape: const RoundedRectangleBorder(borderRadius: KansoRadius.medium),
        padding: const EdgeInsets.symmetric(horizontal: KansoSpace.lg),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Quiet section label with an optional trailing action.
class KansoSectionHeader extends StatelessWidget {
  const KansoSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KansoSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: k.textMuted,
                    letterSpacing: 0.09,
                  ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: k.accentStrong),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Shared empty state — sentence case, no illustration, optional action.
class KansoEmptyState extends StatelessWidget {
  const KansoEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KansoSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: k.accentSecondary),
            const SizedBox(height: KansoSpace.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: KansoSpace.sm),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: k.textMuted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: KansoSpace.xl),
              KansoPrimaryButton(label: actionLabel!, onPressed: onAction, icon: Icons.add_rounded),
            ],
          ],
        ),
      ),
    );
  }
}

/// A centered, quiet loading indicator.
class KansoLoading extends StatelessWidget {
  const KansoLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final k = context.kanso;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: k.accentPrimary),
          ),
          if (message != null) ...[
            const SizedBox(height: KansoSpace.md),
            Text(message!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: k.textMuted)),
          ],
        ],
      ),
    );
  }
}
