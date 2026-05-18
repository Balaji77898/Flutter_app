import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:restaurant_unified_app/core/constants.dart';
import 'package:restaurant_unified_app/core/auth_provider.dart';
import 'package:restaurant_unified_app/staff/contexts/auth_provider.dart';
import 'package:restaurant_unified_app/admin/core/providers/restaurant_provider.dart';
import 'package:restaurant_unified_app/admin/core/providers/notification_provider.dart';
import 'package:restaurant_unified_app/admin/core/models/notification_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isNavigating = false;
  Offset _navStartPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantProvider>().fetchRestaurant();
      final notifProv = context.read<NotificationProvider>();
      notifProv.startPolling();

      // Listen for new notifications to show custom top toast
      notifProv.addListener(() {
        if (notifProv.notifications.isNotEmpty &&
            !notifProv.notifications.first.isRead) {
          final latest = notifProv.notifications.first;
          if (mounted) {
            _showTopToast(latest);
          }
        }
      });
    });
  }

  void _showTopToast(NotificationModel notification) {
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _TopToastWidget(
        notification: notification,
        onDismiss: () => overlayEntry.remove(),
        onView: () {
          overlayEntry.remove();
          context.go('/admin/orders?highlightOrderId=${notification.orderId}');
        },
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }

  @override
  void dispose() {
    // Note: We might want to keep polling if the admin stays in the app
    // but for now we stop when dashboard is disposed
    // context.read<NotificationProvider>().stopPolling();
    super.dispose();
  }

  void _triggerNavAnimation(Offset startPos, String route) async {
    setState(() {
      _navStartPos = startPos;
      _isNavigating = true;
    });

    // Wait for the animation to complete (approx 600ms)
    await Future.delayed(const Duration(milliseconds: 650));

    if (mounted) {
      setState(() => _isNavigating = false);
      context.go(route);
    }
  }

  final _dashboardOptions = [
    const _DashOption(
      title: 'Menu Management',
      description: 'Add, update, or remove menu items.',
      icon: Icons.restaurant_menu_rounded,
      route: '/admin/menu',
    ),
    const _DashOption(
      title: 'Staff Management',
      description: 'Manage billing and serving staff credentials.',
      icon: Icons.people_outline_rounded,
      route: '/admin/staff',
    ),
    const _DashOption(
      title: 'Table Details',
      description: 'Configure layout, view status, and QR codes.',
      icon: Icons.grid_view_rounded,
      route: '/admin/tables',
    ),
    const _DashOption(
      title: 'Order Bill',
      description: 'View daily orders and billing history.',
      icon: Icons.receipt_long_rounded,
      route: '/admin/orders',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final restaurantProv = context.watch<RestaurantProvider>();
    final restaurant = restaurantProv.restaurant;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width <= 1024;
    final isWide = size.width > 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F2),
      body: Column(
        children: [
          // ── Header Section ──────────────────────────────────────────────────
          _buildHeader(context, auth, restaurant, isMobile),

          // ── Main Body Section ───────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                // Clean Elegant "Foggy" Background
                Positioned.fill(
                  child: Container(
                    color: AppColors.ivory,
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: 0.05,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=2070&auto=format&fit=crop',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Dashboard Cards
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 80 : (isTablet ? 40 : 20),
                    vertical: isMobile ? 30 : 60,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: LayoutBuilder(builder: (ctx, constraints) {
                        int cols = 1;
                        double aspect =
                            2.8; // List tile aspect for single column mobile

                        if (constraints.maxWidth > 900) {
                          cols = 4;
                          aspect = 1.0;
                        } else if (constraints.maxWidth > 600) {
                          cols = 2;
                          aspect = 1.1;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: isMobile ? 16 : 24,
                            mainAxisSpacing: isMobile ? 16 : 24,
                            childAspectRatio: aspect,
                          ),
                          itemCount: _dashboardOptions.length,
                          itemBuilder: (ctx, i) => _HoverableDashCard(
                            option: _dashboardOptions[i],
                            index: i,
                            isMobile: isMobile,
                            onTap: (details) => _triggerNavAnimation(
                                details.globalPosition,
                                _dashboardOptions[i].route),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

                if (restaurantProv.isLoading)
                  const LinearProgressIndicator(color: AppColors.rubyRed),

                // Royal Navigation Pulse
                if (_isNavigating) _NavigationPulse(startPos: _navStartPos),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth,
      dynamic restaurant, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.rubyDark,
        border: Border(bottom: BorderSide(color: AppColors.gold, width: 4)),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40, vertical: isMobile ? 16 : 24),
      child: SafeArea(
        bottom: false,
        child: isMobile
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StatusBadge(isActive: restaurant?.isActive ?? true),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _NotificationButton(),
                          const SizedBox(width: 12),
                          _ProfileChip(
                              email: auth.userEmail ?? 'admin@restaurant.com'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    restaurant?.name ?? 'Restaurant Admin',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (restaurant?.restaurantType ?? 'CAFE').toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) {
                          await context.read<StaffAuthProvider>().logout();
                        }
                        if (context.mounted) {
                          context.read<NotificationProvider>().stopPolling();
                          context.go('/login');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded,
                          size: 18, color: Colors.white),
                      label: Text('Logout',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  // Centered Brand Info
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        restaurant?.name ?? 'Restaurant Admin',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (restaurant?.restaurantType ?? 'CAFE')
                                .toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StatusBadge(isActive: restaurant?.isActive ?? true),
                        ],
                      ),
                    ],
                  ),

                  // Right Side Profile & Logout (Stacked)
                  Positioned(
                    right: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _NotificationButton(),
                            const SizedBox(width: 16),
                            _ProfileChip(
                                email:
                                    auth.userEmail ?? 'admin@restaurant.com'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await auth.logout();
                              if (context.mounted) {
                                await context
                                    .read<StaffAuthProvider>()
                                    .logout();
                              }
                              if (context.mounted) {
                                context
                                    .read<NotificationProvider>()
                                    .stopPolling();
                                context.go('/login');
                              }
                            },
                            icon: const Icon(Icons.logout_rounded,
                                size: 16, color: Colors.white),
                            label: Text('Logout',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HoverableDashCard extends StatefulWidget {
  final _DashOption option;
  final int index;
  final bool isMobile;
  final Function(TapDownDetails) onTap;

  const _HoverableDashCard({
    required this.option,
    required this.index,
    required this.isMobile,
    required this.onTap,
  });

  @override
  State<_HoverableDashCard> createState() => _HoverableDashCardState();
}

class _HoverableDashCardState extends State<_HoverableDashCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered ? AppColors.gold : AppColors.rubyDark,
              width: 1.0, // Thin maroon outline
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.rubyDark
                    .withValues(alpha: 0.12), // Persistent maroon shadow
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 15 : 10),
              )
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: widget.isMobile ? 56 : 72,
                height: widget.isMobile ? 56 : 72,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? AppColors.rubyRed
                      : AppColors.rubyDark.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.option.icon,
                  color: _isHovered ? Colors.white : AppColors.rubyDark,
                  size: widget.isMobile ? 24 : 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.option.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: widget.isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.rubyDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.option.description,
                      style: GoogleFonts.inter(
                        fontSize: widget.isMobile ? 12 : 14,
                        color: Colors.grey.shade500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.gold, size: 24),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: (widget.index * 100).ms)
            .slideX(begin: 0.1, curve: Curves.easeOutCirc),
      ),
    );
  }
}

class _DashOption {
  final String title, description, route;
  final IconData icon;
  const _DashOption(
      {required this.title,
      required this.description,
      required this.icon,
      required this.route});
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            isActive ? 'ACTIVE' : 'INACTIVE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.green.shade700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatefulWidget {
  final String email;
  const _ProfileChip({required this.email});

  @override
  State<_ProfileChip> createState() => _ProfileChipState();
}

class _ProfileChipState extends State<_ProfileChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/admin/profile'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: _isHovered
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1)),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 2)
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_pin_rounded,
                  color: _isHovered ? Colors.white : AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.email,
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: _isHovered ? FontWeight.bold : FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationPulse extends StatelessWidget {
  final Offset startPos;
  const _NavigationPulse({required this.startPos});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Arrow
        Positioned.fill(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              // Convert global to local (approximate since we're in a fill Stack)
              final x = startPos.dx;
              final y = startPos.dy - 100; // Account for header height approx

              return Stack(
                children: [
                  // Trail Particles
                  ...List.generate(5, (i) {
                    final particleProgress =
                        (value - (i * 0.1)).clamp(0.0, 1.0);
                    if (particleProgress <= 0 || particleProgress >= 0.8)
                      return const SizedBox();

                    return Positioned(
                      left: x + (particleProgress * 150),
                      top: y - (particleProgress * 50),
                      child: Opacity(
                        opacity: (1 - particleProgress) * 0.3,
                        child: Transform.scale(
                          scale: 0.5 + (particleProgress * 0.5),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: const Icon(Icons.navigation_rounded,
                                color: AppColors.gold, size: 20),
                          ),
                        ),
                      ),
                    );
                  }),

                  // Main Moving Arrow
                  Positioned(
                    left: x + (value * 200),
                    top: y - (value * 80),
                    child: Opacity(
                      opacity: value < 0.8 ? 1.0 : (1.0 - (value - 0.8) * 5),
                      child: Transform.scale(
                        scale: 1.0 + (value * 0.4), // Scale up effect
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold
                                    .withValues(alpha: 0.3 * (1 - value)),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: const Icon(Icons.navigation_rounded,
                                color: AppColors.gold, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NotificationButton extends StatefulWidget {
  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<NotificationProvider>();
    final unread = prov.unreadCount;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _showNotificationOverlay(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _isHovered
                    ? AppColors.gold.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 24),
                if (unread > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showNotificationOverlay(BuildContext context) {
    final prov = context.read<NotificationProvider>();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.only(top: 80, right: 100),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 40,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined,
                        color: AppColors.rubyRed, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Notifications',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.rubyDark,
                      ),
                    ),
                    const Spacer(),
                    if (prov.notifications.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          prov.markAllAsRead();
                          Navigator.pop(context);
                        },
                        child: Text('Mark all as read',
                            style: GoogleFonts.inter(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.ivoryDark),
              if (prov.notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.ivory,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_none_rounded,
                            color: Colors.grey.shade300, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No new notifications',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: prov.notifications.length,
                    itemBuilder: (context, i) {
                      final n = prov.notifications[i];
                      return ListTile(
                        onTap: () {
                          prov.markAsRead(n.id);
                          Navigator.pop(context);
                          context.go(
                              '/admin/orders?highlightOrderId=${n.orderId}');
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: n.isRead
                                ? AppColors.ivory
                                : AppColors.rubyRed.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            color: n.isRead ? Colors.grey : AppColors.rubyRed,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          n.message,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight:
                                n.isRead ? FontWeight.w500 : FontWeight.bold,
                            color: AppColors.slate900,
                          ),
                        ),
                        subtitle: _LiveTimeAgo(dt: n.createdAt),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 4),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTimeAgo extends StatefulWidget {
  final DateTime dt;
  const _LiveTimeAgo({required this.dt});

  @override
  State<_LiveTimeAgo> createState() => _LiveTimeAgoState();
}

class _LiveTimeAgoState extends State<_LiveTimeAgo> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every 30 seconds to keep the "time ago" accurate
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(widget.dt),
      style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate400),
    );
  }

  String _format(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _TopToastWidget extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onDismiss;
  final VoidCallback onView;

  const _TopToastWidget({
    required this.notification,
    required this.onDismiss,
    required this.onView,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 40,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: 0.95), // Transparent white
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.rubyRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppColors.rubyRed, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      widget.notification.message,
                      style: GoogleFonts.inter(
                        color: AppColors.rubyDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: widget.onView,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.rubyRed,
                      textStyle: GoogleFonts.inter(
                          fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    child: const Text('VIEW'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () =>
                        _controller.reverse().then((_) => widget.onDismiss()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
