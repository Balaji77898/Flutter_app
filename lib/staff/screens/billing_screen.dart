import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../contexts/orders_provider.dart';
import '../contexts/auth_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final ordersProvider = context.read<OrdersProvider>();
    final auth = context.read<StaffAuthProvider>();
    
    if (auth.token != null && ordersProvider.orders.isEmpty) {
      await ordersProvider.fetchOrders(auth.token!);
    }
  }

  Map<String, dynamic> _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.served:
      case OrderStatus.billed:
        return {
          'label': 'BILLED',
          'bg': AppColors.warningLight,
          'color': AppColors.warning,
          'icon': Icons.access_time,
        };
      case OrderStatus.paid:
        return {
          'label': 'PAID',
          'bg': AppColors.successLight,
          'color': AppColors.success,
          'icon': Icons.check_circle_outline,
        };
      default:
        return {
          'label': 'PENDING',
          'bg': AppColors.warningLight,
          'color': AppColors.warning,
          'icon': Icons.pending_actions,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    // In actual app, we only show billed/paid or served items in billing
    final billingOrders = ordersProvider.orders
    .where(
      (o) =>
          o.status == OrderStatus.served ||
          o.status == OrderStatus.billed ||
          o.status == OrderStatus.paid,
    )
    .toList();

    final totalRevenue = billingOrders
        .where((o) => o.status == OrderStatus.paid)
        .fold(0.0, (sum, o) => sum + o.total);

    final totalBilled = billingOrders
        .where(
          (o) =>
              o.status == OrderStatus.served || o.status == OrderStatus.billed,
        )
        .fold(0.0, (sum, o) => sum + o.total);

    final grandTotal = totalRevenue + totalBilled;

    final filters = [
      {'id': 'all', 'label': 'All Bills', 'count': billingOrders.length},
      {
        'id': 'unpaid',
        'label': 'Unpaid',
        'count': billingOrders
            .where(
              (o) =>
                  o.status == OrderStatus.served ||
                  o.status == OrderStatus.billed,
            )
            .length,
      },
      {
        'id': 'paid',
        'label': 'Paid',
        'count': billingOrders
            .where((o) => o.status == OrderStatus.paid)
            .length,
      },
    ];

    List<Order> filteredOrders;
    if (_activeFilter == 'all') {
      filteredOrders = billingOrders;
    } else if (_activeFilter == 'unpaid') {
      filteredOrders = billingOrders
          .where(
            (o) =>
                o.status == OrderStatus.served ||
                o.status == OrderStatus.billed,
          )
          .toList();
    } else {
      filteredOrders = billingOrders
          .where((o) => o.status == OrderStatus.paid)
          .toList();
    }

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          const PageHeader(
            title: 'Billing & Payments',
            subtitle: 'Manage Transactions and Revenue',
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 768;

                // Revenue Stats Row
                    final statsRow = GridView.count(
                      crossAxisCount: isWide
                          ? (constraints.maxWidth >= 1024 ? 3 : 2)
                          : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: isWide ? 2.5 : 2.7,
                      children: [
                    StatCard(
                      icon: Icons.account_balance_wallet,
                      iconColor: AppColors.warning,
                      iconBg: AppColors.warningLight,
                      label: 'Total Revenue',
                      value: '₹${grandTotal.round()}',
                    ),
                    StatCard(
                      icon: Icons.payments,
                      iconColor: AppColors.success,
                      iconBg: AppColors.successLight,
                      label: 'Collected',
                      value: '₹${totalRevenue.round()}',
                    ),
                    if (isWide && constraints.maxWidth >= 1024)
                      StatCard(
                        icon: Icons.access_time,
                        iconColor: AppColors.warning,
                        iconBg: AppColors.warningLight,
                        label: 'Billed',
                        value: '₹${totalBilled.round()}',
                      ),
                  ],
                );

                Widget filterList = isWide
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: filters
                            .map((f) => _buildFilterButton(f, isWide))
                            .toList(),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: filters
                              .map(
                                (f) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildFilterButton(f, isWide),
                                ),
                              )
                              .toList(),
                        ),
                      );

                Widget content = filteredOrders.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt,
                        title: 'No bills found',
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide
                              ? (constraints.maxWidth >= 1024 ? 2 : 1)
                              : 1,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: isWide ? 1.8 : 1.3,
                        ),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final config = _getStatusConfig(order.status);
                          return _BillingCard(order: order, config: config);
                        },
                      );

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          statsRow,
                          const SizedBox(height: 32),
                          isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Sidebar Filter
                                    Container(
                                      width: 256,
                                      margin: const EdgeInsets.only(right: 32),
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: const Color(0xFFF1F5F9),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'PAYMENT STATUS',
                                            style: AppTheme.sans(
                                              size: 12,
                                              weight: FontWeight.w700,
                                              color: AppColors.slate400,
                                            ).copyWith(letterSpacing: 1.0),
                                          ),
                                          const SizedBox(height: 16),
                                          filterList,
                                        ],
                                      ),
                                    ),
                                    // Grid
                                    Expanded(child: content),
                                  ],
                                )
                              : Column(
                                  children: [
                                    filterList,
                                    const SizedBox(height: 24),
                                    content,
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(Map<String, dynamic> f, bool isWide) {
    final isActive = _activeFilter == f['id'];
    return Padding(
      padding: isWide ? const EdgeInsets.only(bottom: 8) : EdgeInsets.zero,
      child: InkWell(
        onTap: () => setState(() => _activeFilter = f['id'] as String),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                f['label'] as String,
                style: AppTheme.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  color: isActive ? AppColors.white : AppColors.slate900,
                ),
              ),
              if (isWide) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.ivory,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${f['count']}',
                  style: AppTheme.sans(
                    size: 12,
                    weight: FontWeight.w700,
                    color: isActive ? AppColors.white : AppColors.slate500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillingCard extends StatelessWidget {
  final Order order;
  final Map<String, dynamic> config;

  const _BillingCard({required this.order, required this.config});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 400;

    return GestureDetector(
      onTap: () {
  if (order.status == OrderStatus.served ||
      order.status == OrderStatus.billed) {
    context.push('/staff/payment/${order.id}');
  }
},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: config['bg'] as Color,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        config['icon'] as IconData,
                        size: 28,
                        color: config['color'] as Color,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config['label'] as String,
                            style: AppTheme.sans(
                              size: 18,
                              weight: FontWeight.w900,
                              color: config['color'] as Color,
                            ).copyWith(letterSpacing: 0.5),
                          ),
                          Text(
                            'Order #${order.id.substring(0, 4)}',
                            style: AppTheme.sans(
                              size: 14,
                              color: (config['color'] as Color).withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 24,
                    color: config['color'] as Color,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isSmall ? 16 : 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: isSmall ? 40 : 48,
                            height: isSmall ? 40 : 48,
                            decoration: BoxDecoration(
                              color: AppColors.slate50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.receipt_long,
                              color: AppColors.primary,
                              size: isSmall ? 20 : 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  order.table,
                                  style: AppTheme.sans(
                                    size: isSmall ? 16 : 20,
                                    weight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${order.items} items',
                                  style: AppTheme.sans(
                                    size: isSmall ? 12 : 14,
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${order.total.round()}',
                          style: AppTheme.sans(
                            size: isSmall ? 22 : 28,
                            weight: FontWeight.w900,
                            color: AppColors.slate900,
                          ),
                        ),
                        if (order.status == OrderStatus.served ||
                            order.status == OrderStatus.billed) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: isSmall ? 36 : null,
                            child: PrimaryButton(
                              label: 'Pay Now',
                              color: AppColors.gold,
                              onTap: () => context.push('/staff/payment/${order.id}'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
