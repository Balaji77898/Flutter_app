import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../contexts/auth_provider.dart';
import '../contexts/orders_provider.dart';
import '../contexts/tables_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    final auth = context.watch<StaffAuthProvider>();
    final tablesProvider = context.watch<TablesProvider>();

    final recentOrders = ordersProvider.activeOrders.take(4).toList();
    final newOrdersCount = ordersProvider.newOrders.length;
    final activeOrdersCount = ordersProvider.activeOrders.length;
    final availableTablesCount =
        tablesProvider.tables.where((t) => t.status == TableStatus.available).length;

    final userName = auth.user?.name ?? 'Staff';
    final firstName = userName.split(' ').first;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Stack(
        children: [
          // Subtle background pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/cubes.png',
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          
          Column(
            children: [
              // ── Hero Greeting Banner ──────────────────────────────────────
              _DashboardHero(
                greeting: _getGreeting(),
                firstName: firstName,
                newOrdersCount: newOrdersCount,
                activeOrdersCount: activeOrdersCount,
                availableTablesCount: availableTablesCount,
              ),

              // ── Scrollable content ────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: isMobile ? 24 : 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Section label ──
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'QUICK ACTIONS',
                                style: AppTheme.sans(
                                  color: AppColors.slate500,
                                  size: 11,
                                  weight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Feature Grid ──────────────────────────────────
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              int crossAxisCount = 2;
                              if (width >= 1024) {
                                crossAxisCount = 4;
                              } else if (width >= 600) {
                                crossAxisCount = 2;
                              }

                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: isMobile ? 12 : 20,
                                mainAxisSpacing: isMobile ? 12 : 20,
                                childAspectRatio: isMobile ? 0.95 : 0.85,
                                children: [
                                  _FeatureCard(
                                    icon: Icons.add_shopping_cart_rounded,
                                    iconColor: AppColors.primary,
                                    iconBg: AppColors.primary.withValues(alpha: 0.08),
                                    title: 'Create Order',
                                    description: 'Start a new table order',
                                    onTap: () => context.push('/staff/create-order'),
                                  ),
                                  _FeatureCard(
                                    icon: Icons.notifications_active_rounded,
                                    iconColor: const Color(0xFFD97706),
                                    iconBg: const Color(0xFFFFFBEB),
                                    title: 'Requests',
                                    description: 'View incoming orders',
                                    badge: newOrdersCount > 0 ? '$newOrdersCount' : null,
                                    onTap: () => context.push('/staff/new-orders'),
                                  ),
                                  _FeatureCard(
                                    icon: Icons.receipt_long_rounded,
                                    iconColor: const Color(0xFF0D9488),
                                    iconBg: const Color(0xFFF0FDFA),
                                    title: 'Active Orders',
                                    description: 'Manage live orders',
                                    badge: activeOrdersCount > 0 ? '$activeOrdersCount' : null,
                                    onTap: () => context.push('/staff/orders'),
                                  ),
                                  _FeatureCard(
                                    icon: Icons.grid_view_rounded,
                                    iconColor: AppColors.slate600,
                                    iconBg: AppColors.slate50,
                                    title: 'Tables',
                                    description: 'Floor plan overview',
                                    badge: availableTablesCount > 0 ? '$availableTablesCount free' : null,
                                    badgeColor: AppColors.success,
                                    onTap: () => context.push('/staff/tables'),
                                  ),
                                ]
                                    .asMap()
                                    .entries
                                    .map((e) => e.value
                                        .animate(delay: Duration(milliseconds: e.key * 80))
                                        .fade(duration: 400.ms)
                                        .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOutQuad))
                                    .toList(),
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // ── Active Orders Section ─────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: AppColors.slate100,
                              ),
                            ),
                            padding: EdgeInsets.all(isMobile ? 24 : 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Active Orders',
                                            style: AppTextStyles.headline(
                                              color: AppColors.slate900,
                                              size: isMobile ? 20 : 24,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Live dining room updates',
                                            style: AppTheme.sans(
                                              color: AppColors.slate400,
                                              size: isMobile ? 12 : 13,
                                              weight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GoldButton(
                                      label: isMobile ? 'All' : 'View All',
                                      icon: Icons.arrow_forward_rounded,
                                      onTap: () => context.push('/staff/orders'),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                if (recentOrders.isEmpty)
                                  const EmptyState(
                                    icon: Icons.receipt_long_outlined,
                                    title: 'No active orders',
                                    subtitle: 'Live orders will appear here',
                                  )
                                else
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      int cols = 1;
                                      if (constraints.maxWidth >= 1200) {
                                        cols = 4;
                                      } else if (constraints.maxWidth >= 900) {
                                        cols = 3;
                                      } else if (constraints.maxWidth >= 600) {
                                        cols = 2;
                                      }

                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cols,
                                          mainAxisSpacing: 16,
                                          crossAxisSpacing: 16,
                                          childAspectRatio: isMobile ? 2.5 : 1.6,
                                        ),
                                        itemCount: recentOrders.length,
                                        itemBuilder: (ctx, i) => _MiniOrderCard(order: recentOrders[i])
                                            .animate(delay: Duration(milliseconds: i * 60))
                                            .fade(duration: 300.ms)
                                            .slideY(begin: 0.1, end: 0, duration: 300.ms),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ).animate().fade(duration: 500.ms, delay: 300.ms).slideY(begin: 0.05, duration: 500.ms, curve: Curves.easeOutQuad),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

// ─── Hero Greeting Banner ──────────────────────────────────────────────────
class _DashboardHero extends StatelessWidget {
  final String greeting;
  final String firstName;
  final int newOrdersCount;
  final int activeOrdersCount;
  final int availableTablesCount;

  const _DashboardHero({
    required this.greeting,
    required this.firstName,
    required this.newOrdersCount,
    required this.activeOrdersCount,
    required this.availableTablesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        image: DecorationImage(
          image: const NetworkImage('https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?q=80&w=2070&auto=format&fit=crop'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.primaryDark.withValues(alpha: 0.85),
            BlendMode.srcOver,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glass overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.4),
                    AppColors.primaryDark.withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          
          // Background decorative elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Brand & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LIVE SYSTEM',
                              style: AppTheme.sans(
                                size: 10,
                                weight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                        child: Text(
                          firstName[0],
                          style: AppTheme.serif(
                            size: 16,
                            weight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 600.ms).slideY(begin: -0.2),

                  const SizedBox(height: 28),

                  // Greeting Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${greeting.toUpperCase()},',
                        style: AppTheme.sans(
                          size: 12,
                          weight: FontWeight.w800,
                          color: AppColors.gold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        firstName,
                        style: AppTheme.serif(
                          size: 40,
                          weight: FontWeight.w900,
                          color: AppColors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ).animate().fade(duration: 600.ms, delay: 200.ms).slideX(begin: -0.1),

                  const SizedBox(height: 32),

                  // Live Stats Row
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _StatPill(
                            icon: Icons.receipt_long_rounded,
                            value: '$activeOrdersCount',
                            label: 'Active',
                          ),
                          _StatPill(
                            icon: Icons.notifications_active_rounded,
                            value: '$newOrdersCount',
                            label: 'Pending',
                            isAlert: newOrdersCount > 0,
                          ),
                          _StatPill(
                            icon: Icons.grid_view_rounded,
                            value: '$availableTablesCount',
                            label: 'Tables Free',
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 600.ms, delay: 400.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isAlert;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    this.isAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isAlert ? AppColors.danger.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isAlert ? AppColors.danger : AppColors.gold,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTheme.sans(
                  size: 16,
                  weight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                label.toUpperCase(),
                style: AppTheme.sans(
                  size: 9,
                  weight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.6),
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


// ─── Feature Card ──────────────────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
          duration: 150.ms,
          child: AnimatedContainer(
            duration: 200.ms,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(isSmall ? 24 : 32),
              border: Border.all(
                color: _isPressed || _isHovered
                    ? AppColors.gold.withValues(alpha: 0.3)
                    : AppColors.slate100,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isHovered || _isPressed)
                      ? AppColors.gold.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.all(isSmall ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  width: isSmall ? 48 : 60,
                  height: isSmall ? 48 : 60,
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: widget.iconColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon,
                      color: widget.iconColor, size: isSmall ? 24 : 28),
                ),
                const Spacer(),
                // Badge
                if (widget.badge != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (widget.badgeColor ?? AppColors.danger)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.badge!,
                      style: AppTheme.sans(
                        size: 9,
                        weight: FontWeight.w900,
                        color: widget.badgeColor ?? AppColors.danger,
                      ),
                    ),
                  ),
                // Text content
                Text(
                  widget.title,
                  style: AppTextStyles.title(
                    color: AppColors.slate900,
                    size: isSmall ? 15 : 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.description,
                  style: AppTextStyles.body(
                    color: AppColors.slate400,
                    size: isSmall ? 11 : 12,
                  ),
                  maxLines: isSmall ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Mini Order Card ───────────────────────────────────────────────────────
class _MiniOrderCard extends StatelessWidget {
  final Order order;
  const _MiniOrderCard({required this.order});

  _StatusConfig _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return _StatusConfig(
          label: 'PENDING',
          bg: const Color(0xFFFEF3C7),
          color: const Color(0xFFD97706),
          leftBar: const Color(0xFFF59E0B),
        );
      case OrderStatus.preparing:
        return _StatusConfig(
          label: 'PREPARING',
          bg: const Color(0xFFDBEAFE),
          color: const Color(0xFF2563EB),
          leftBar: const Color(0xFF3B82F6),
        );
      case OrderStatus.ready:
        return _StatusConfig(
          label: 'READY',
          bg: const Color(0xFFD1FAE5),
          color: const Color(0xFF059669),
          leftBar: const Color(0xFF10B981),
        );
      default:
        return _StatusConfig(
          label: 'SERVED',
          bg: AppColors.slate100,
          color: AppColors.slate500,
          leftBar: AppColors.slate300,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(order.status);

    return GestureDetector(
      onTap: () => context.push('/staff/order-details/${order.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Status corner accent
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: config.bg,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  config.label,
                  style: AppTheme.sans(
                    size: 9,
                    weight: FontWeight.w900,
                    color: config.color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Number
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.table,
                              style: AppTextStyles.title(
                                color: AppColors.slate900,
                                size: 16,
                              ),
                            ),
                            Text(
                              '#${order.id.substring(0, 6)}',
                              style: AppTheme.sans(
                                size: 11,
                                color: AppColors.slate400,
                                weight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Details Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.slate400),
                          const SizedBox(width: 4),
                          Text(
                            '${order.items} items',
                            style: AppTheme.sans(
                              size: 12,
                              color: AppColors.slate600,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${order.total.round()}',
                        style: AppTextStyles.numeric(
                          color: AppColors.slate900,
                          size: 18,
                        ),
                      ),
                    ],
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

class _StatusConfig {
  final String label;
  final Color bg;
  final Color color;
  final Color leftBar;

  const _StatusConfig({
    required this.label,
    required this.bg,
    required this.color,
    required this.leftBar,
  });
}

