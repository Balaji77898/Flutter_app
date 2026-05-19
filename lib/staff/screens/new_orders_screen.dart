import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../contexts/orders_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../../core/currency_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../contexts/auth_provider.dart';

class NewOrdersScreen extends StatefulWidget {
  const NewOrdersScreen({super.key});

  @override
  State<NewOrdersScreen> createState() => _NewOrdersScreenState();
}

class _NewOrdersScreenState extends State<NewOrdersScreen> {
  bool _showNewestFirst = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final auth = context.read<StaffAuthProvider>();
    final ordersProvider = context.read<OrdersProvider>();
    if (auth.token != null) {
      await ordersProvider.fetchOrders(auth.token!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();
    final newOrders = List<Order>.from(provider.newOrders);

    // Sort by createdAt
    newOrders.sort(
      (a, b) => _showNewestFirst
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt),
    );

    final acceptedCount = provider.activeOrders.length;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          PageHeader(
            title: 'New Orders',
            subtitle: 'Incoming Kitchen Orders',
            onBack: () => context.pop(),
            actions: [
              const SizedBox(width: 8),
              HeaderIconButton(
                icon: Icons.refresh,
                onTap: () {
                  final token = context.read<StaffAuthProvider>().token;
                  if (token != null) {
                    context.read<OrdersProvider>().fetchOrders(token);
                  }
                },
              ),
              const SizedBox(width: 8),
              HeaderIconButton(
                icon: _showNewestFirst
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                label: _showNewestFirst ? 'Newest First' : 'Oldest First',
                onTap: () =>
                    setState(() => _showNewestFirst = !_showNewestFirst),
              ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats sidebar on large screens (shown inline on small)
                _buildContent(context, newOrders, acceptedCount, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Order> newOrders,
    int acceptedCount,
    OrdersProvider provider,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Stats row
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.notifications_outlined,
                    iconColor: AppColors.primary,
                    iconBg: const Color(0xFFFEE2E2),
                    label: 'New Orders',
                    value: '${newOrders.length}',
                  ).animate().fade().scale(
                        curve: Curves.easeOutBack,
                        duration: 400.ms,
                      ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatBox(
                    icon: Icons.check_circle_outline,
                    iconColor: AppColors.gold,
                    iconBg: const Color(0xFFFEF9E7),
                    label: 'Accepted',
                    value: '$acceptedCount',
                  ).animate().fade().scale(
                        curve: Curves.easeOutBack,
                        duration: 400.ms,
                        delay: 100.ms,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (newOrders.isEmpty)
              const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                subtitle: 'New customer orders will appear here',
              ).animate().fade(duration: 400.ms).slideY(
                    begin: 0.1,
                    duration: 400.ms,
                    curve: Curves.easeOutQuad,
                  )
            else
              ...newOrders.asMap().entries.map(
                    (entry) =>
                        _OrderCard(order: entry.value, provider: provider)
                            .animate()
                            .fade(duration: 400.ms, delay: (entry.key * 100).ms)
                            .slideX(
                              begin: 0.1,
                              end: 0,
                              duration: 400.ms,
                              curve: Curves.easeOutQuad,
                            ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  const _StatBox({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: AppTheme.sans(
              size: 11,
              color: AppColors.slate500,
              weight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.sans(
              size: 32,
              weight: FontWeight.w900,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final OrdersProvider provider;

  const _OrderCard({required this.order, required this.provider});

  @override
  Widget build(BuildContext context) {
    final isNew = order.status == OrderStatus.placed;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNew
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.slate100,
        ),
        boxShadow: [
          BoxShadow(
            color: isNew
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status Header
          Container(
            decoration: BoxDecoration(
              gradient: isNew
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    )
                  : null,
              color: isNew ? null : const Color(0xFFECFDF5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                if (isNew) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEW ORDER',
                          style: AppTheme.sans(
                            size: 16,
                            weight: FontWeight.w900,
                            color: AppColors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              order.time,
                              style: AppTheme.sans(
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              ' • ',
                              style: AppTheme.sans(
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            LiveTimeAgo(
                              dt: order.createdAt,
                              style: AppTheme.sans(
                                size: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      order.orderNumber,
                      style: AppTheme.sans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACCEPTED',
                        style: AppTheme.sans(
                          size: 15,
                          weight: FontWeight.w900,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            order.time,
                            style: AppTheme.sans(
                              size: 12,
                              color: const Color(
                                0xFF065F46,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            ' • ',
                            style: AppTheme.sans(
                              size: 12,
                              color: const Color(
                                0xFF065F46,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            order.orderNumber,
                            style: AppTheme.sans(
                              size: 12,
                              color: const Color(
                                0xFF065F46,
                              ).withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.ivory,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.table,
                            style: AppTheme.sans(
                              size: 20,
                              weight: FontWeight.w900,
                              color: AppColors.slate900,
                            ),
                          ),
                          Text(
                            '${order.items} items',
                            style: AppTheme.sans(
                              size: 13,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyUtils.format(order.total),
                      style: AppTheme.sans(
                        size: 26,
                        weight: FontWeight.w900,
                        color: AppColors.slate900,
                      ),
                    ),
                  ],
                ),
                if (order.customerName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.ivory,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CUSTOMER',
                              style: AppTheme.sans(
                                size: 10,
                                color: AppColors.slate500,
                                weight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              order.customerName!,
                              style: AppTheme.sans(
                                size: 14,
                                weight: FontWeight.w600,
                                color: AppColors.slate900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORDER ITEMS',
                        style: AppTheme.sans(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.slate500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...order.itemsPreview.take(3).map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item,
                                    style: AppTheme.sans(
                                      size: 13,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (order.itemsPreview.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            '+${order.itemsPreview.length - 3} more items',
                            style: AppTheme.sans(
                              size: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                if (isNew)
                  GestureDetector(
                    onTap: () {
                      final token = context.read<StaffAuthProvider>().token;
                      provider.updateOrderStatus(
                        order.id,
                        OrderStatus.confirmed,
                        token!,
                      );
                      context.push('/staff/order-details/${order.id}');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.goldLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ACCEPT ORDER',
                            style: AppTheme.sans(
                              size: 15,
                              weight: FontWeight.w900,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () =>
                        context.push('/staff/order-details/${order.id}'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Details',
                            style: AppTheme.sans(
                              size: 14,
                              weight: FontWeight.w700,
                              color: AppColors.slate700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: AppColors.slate500,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
