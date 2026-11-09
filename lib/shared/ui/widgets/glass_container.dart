import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Signature ROCI's GlassContainer widget.
/// Provides dynamic glassmorphism with real-time backdrop blur and tint interpolation.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Color? color;
  final bool isSelected;
  final Color? selectedBorderColor;
  final double? elevation;
  final bool enableGlass;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.15,
    this.borderRadius,
    this.padding,
    this.margin,
    this.border,
    this.color,
    this.isSelected = false,
    this.selectedBorderColor,
    this.elevation,
    this.enableGlass = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final useGlass = enableGlass && !kIsWeb;

    // ROCI's dynamic tint blending: 12% light mode, 18% dark mode
    final tintColor = color ?? theme.colorScheme.primary;
    final baseColor = isDark ? const Color(0xFF151824) : Colors.white;
    final glassColor = Color.lerp(baseColor, tintColor, isDark ? 0.18 : 0.12)!;

    final radius = borderRadius ?? BorderRadius.circular(24.0);

    // Subtle border tinted with primary or category color
    final borderTint = color ?? theme.colorScheme.primary;
    final glassBorder = border ??
        Border.all(
          color: isSelected
              ? (selectedBorderColor ?? theme.colorScheme.primary)
              : (isDark
                  ? borderTint.withValues(alpha: 0.15)
                  : borderTint.withValues(alpha: 0.10)),
          width: isSelected ? 2.0 : 1.0,
        );

    final double shadowElevation = elevation ?? (useGlass ? 0.0 : 2.0);
    final List<BoxShadow>? shadow = (!useGlass && shadowElevation > 0.0)
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: shadowElevation * 2.0 + 2.0,
              spreadRadius: 0.0,
              offset: Offset(0, shadowElevation),
            ),
          ]
        : null;

    final innerContainer = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: useGlass
            ? glassColor.withValues(alpha: isSelected ? opacity + 0.10 : opacity)
            : (isSelected
                ? (color?.withValues(alpha: 0.20) ?? theme.colorScheme.primaryContainer)
                : (color ?? theme.colorScheme.surfaceContainerLow)),
        borderRadius: radius,
        border: useGlass
            ? glassBorder
            : (isSelected ? glassBorder : Border.all(color: Colors.transparent)),
        boxShadow: shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );

    if (!useGlass) {
      return Container(
        margin: margin,
        child: innerContainer,
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: innerContainer,
        ),
      ),
    );
  }
}
