import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool hasGlow;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.constraints,
    this.maxWidth,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.blur = 0.0, // Default 0.0 eliminates 100% of offscreen rasterization jank
    this.color,
    this.gradient,
    this.border,
    this.onTap,
    this.onLongPress,
    this.hasGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = BorderRadius.circular(borderRadius);
    final effectiveBoxShadow = hasGlow
        ? [
            BoxShadow(
              color: AppTheme.primaryBlue.withAlpha(45),
              blurRadius: 20,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(160),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withAlpha(130),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ];

    final effectiveDecoration = BoxDecoration(
      color: color ?? (gradient == null ? const Color(0xF7111D35) : null),
      gradient: color == null
          ? (gradient ??
              const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xF716253F), // 97% opaque rich dark slate
                  Color(0xFD091020), // 99% opaque deep midnight navy
                ],
              ))
          : null,
      borderRadius: effectiveBorderRadius,
      border: border ??
          Border.all(
            color: AppTheme.glassBorderLight.withAlpha(110),
            width: 1.2,
          ),
      boxShadow: effectiveBoxShadow,
    );

    Widget content;
    if (blur > 0) {
      content = Container(
        width: width,
        height: height,
        constraints: constraints ?? (maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null),
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: effectiveBoxShadow,
        ),
        child: ClipRRect(
          borderRadius: effectiveBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding ?? const EdgeInsets.all(16),
              decoration: effectiveDecoration.copyWith(boxShadow: null),
              child: child,
            ),
          ),
        ),
      );
    } else {
      content = Container(
        width: width,
        height: height,
        constraints: constraints ?? (maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null),
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: effectiveDecoration,
        child: child,
      );
    }

    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveBorderRadius,
        child: InkWell(
          borderRadius: effectiveBorderRadius,
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: AppTheme.primaryBlue.withAlpha(30),
          highlightColor: AppTheme.primaryAccent.withAlpha(20),
          child: content,
        ),
      );
    }

    return content;
  }
}
