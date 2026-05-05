import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

// ─── Header Component ────────────────────────────────────────────────────────
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget>? actions;
  final bool isCentered;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions,
    this.isCentered = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final align = isCentered
            ? CrossAxisAlignment.center
            : (isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center);
        final textAlign = isCentered
            ? TextAlign.center
            : (isWide ? TextAlign.left : TextAlign.center);
        final verticalPadding = isWide ? 64.0 : 40.0;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Abstract Background Patterns
              Positioned(
                top: -50,
                right: -50,
                child: _HeaderPattern(
                  size: 300,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -20,
                child: _HeaderPattern(
                  size: 200,
                  color: AppColors.gold.withValues(alpha: 0.08),
                ),
              ),
              // Gold diagonal shimmer stripe
              Positioned(
                top: 0,
                bottom: 0,
                right: 60,
                child: Container(
                  width: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.gold.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: verticalPadding,
                  ),
                  child: isWide && !isCentered
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: align,
                              children: [
                                _Title(
                                  title: title,
                                  textAlign: textAlign,
                                  isWide: isWide,
                                ),
                                const SizedBox(height: 8),
                                _Subtitle(
                                  subtitle: subtitle,
                                  textAlign: textAlign,
                                  isWide: isWide,
                                ),
                              ],
                            ).animate().fade(duration: 600.ms).slideX(begin: -0.2, curve: Curves.easeOutQuad),
                            if (actions != null)
                              Row(children: actions!)
                                .animate().fade(duration: 600.ms, delay: 200.ms).slideX(begin: 0.2, curve: Curves.easeOutQuad),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: align,
                          children: [
                            _Title(
                              title: title,
                              textAlign: textAlign,
                              isWide: isWide,
                            ).animate().fade(duration: 600.ms).slideY(begin: -0.2, curve: Curves.easeOutQuad),
                            const SizedBox(height: 8),
                            _Subtitle(
                              subtitle: subtitle,
                              textAlign: textAlign,
                              isWide: isWide,
                            ).animate().fade(duration: 600.ms, delay: 100.ms).slideY(begin: -0.1, curve: Curves.easeOutQuad),
                            if (actions != null) ...[
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: actions!,
                              ).animate().fade(duration: 600.ms, delay: 300.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
                            ],
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderPattern extends StatelessWidget {
  final double size;
  final Color color;
  const _HeaderPattern({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  final String title;
  final TextAlign textAlign;
  final bool isWide;
  const _Title({
    required this.title,
    required this.textAlign,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: textAlign,
      style: AppTheme.serif(
        size: isWide ? 56 : 36,
        weight: FontWeight.w800,
        color: AppColors.white,
        letterSpacing: -1,
      ).copyWith(
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final String subtitle;
  final TextAlign textAlign;
  final bool isWide;
  const _Subtitle({
    required this.subtitle,
    required this.textAlign,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      subtitle.toUpperCase(),
      textAlign: textAlign,
      style: AppTheme.sans(
        size: isWide ? 14 : 12,
        weight: FontWeight.w700,
        color: AppColors.gold,
        letterSpacing: 3.0,
      ),
    );
  }
}

// ─── Header Icon Button ───────────────────────────────────────────────────
class HeaderIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? label;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
  });

  @override
  State<HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<HeaderIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: 100.ms,
        child: widget.label != null
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppShadows.goldGlow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      widget.label!,
                      style: AppTheme.sans(
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  boxShadow: [
                    if (_isPressed)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                  ],
                ),
                child: Icon(widget.icon, color: AppColors.white, size: 26),
              ),
      ),
    );
  }
}

// ─── App Card Component ───────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool animateOnTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.onTap,
    this.animateOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.slate100),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return _AnimatedTap(
        onTap: onTap!,
        animate: animateOnTap,
        child: card,
      );
    }
    return card;
  }
}

class _AnimatedTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool animate;
  const _AnimatedTap(
      {required this.child, required this.onTap, this.animate = true});

  @override
  State<_AnimatedTap> createState() => _AnimatedTapState();
}

class _AnimatedTapState extends State<_AnimatedTap> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return GestureDetector(onTap: widget.onTap, child: widget.child);
    }
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: 100.ms,
        child: widget.child,
      ),
    );
  }
}

// ─── Primary Button ────────────────────────────────────────────────────────
class PrimaryButton extends StatefulWidget {
  final String label;
  final Future<void> Function()? onTap;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.icon,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? AppColors.primary;
    final textC = widget.textColor ?? AppColors.white;
    final isSmall = MediaQuery.of(context).size.width < 400;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading || widget.onTap == null
          ? null
          : () async {
              await widget.onTap!();
            },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: 150.ms,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 16 : 28, vertical: isSmall ? 10 : 18),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(isSmall ? 12 : 18),
            boxShadow: [
              if (!widget.isLoading)
                BoxShadow(
                  color: bg.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
            ],
            gradient: widget.color == null
                ? LinearGradient(
                    colors: [bg, bg.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: isSmall ? 18 : 24,
                    height: isSmall ? 18 : 24,
                    child: CircularProgressIndicator(
                      color: textC,
                      strokeWidth: 2.0,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: textC, size: isSmall ? 16 : 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: AppTheme.sans(
                          size: isSmall ? 13 : 16,
                          weight: FontWeight.w800,
                          color: textC,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

}

// ─── Gold Button ───────────────────────────────────────────────────────────
/// Gold gradient CTA button with maroon text — for primary actions
class GoldButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool isLoading;

  const GoldButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: 130.ms,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppShadows.goldGlow,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: AppTheme.sans(
                        size: 14,
                        weight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── Shimmer Loading ──────────────────────────────────────────────────────
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: 1500.ms)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: const [
                Color(0xFFEBEBEB),
                Color(0xFFF4F4F4),
                Color(0xFFEBEBEB),
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.0 + _controller.value * 2, -0.3),
              end: Alignment(1.0 + _controller.value * 2, 0.3),
            ),
          ),
        );
      },
    );
  }
}

// ─── Empty State Component ────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: AppShadows.card,
            ),
            child: Icon(icon, size: 56, color: AppColors.slate300),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
              begin: -5, end: 5, duration: 2000.ms, curve: Curves.easeInOut),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTheme.serif(
              size: 24,
              weight: FontWeight.w700,
              color: AppColors.slate900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTheme.sans(size: 16, color: AppColors.slate500),
            ),
          ],
        ],
      ).animate().fade(duration: 600.ms).scale(
          begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
    );
  }
}

// ─── Status Badge Component ───────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color color;

  const StatusBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.sans(
          size: 11,
          weight: FontWeight.w900,
          color: color,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── Stat Card Component ──────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;

    return AppCard(
      padding: EdgeInsets.all(isSmall ? 18 : 24),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 14 : 18),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
            ),
            child: Icon(icon, color: iconColor, size: isSmall ? 26 : 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTheme.sans(
                    size: isSmall ? 12 : 14,
                    weight: FontWeight.w700,
                    color: AppColors.slate500,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTheme.serif(
                      size: isSmall ? 24 : 28,
                      weight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTheme.sans(
                        size: isSmall ? 11 : 13, color: AppColors.slate400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Compact Stat Chip — for Dashboard stat strip ─────────────────────────
class CompactStatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;

  const CompactStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: accentColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTheme.sans(
                  size: 18,
                  weight: FontWeight.w900,
                  color: AppColors.white,
                ),
              ),
              Text(
                label,
                style: AppTheme.sans(
                  size: 10,
                  weight: FontWeight.w600,
                  color: AppColors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
