import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../contexts/auth_provider.dart';
import '../contexts/orders_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../utils/printing_utils.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
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
    if (auth.token != null && ordersProvider.orders.isEmpty) {
      await ordersProvider.fetchOrders(auth.token!);
    }
  }

  Map<String, dynamic> _getConfig(OrderStatus s) {
    switch (s) {
      case OrderStatus.confirmed:
        return {
          'label': 'CONFIRMED',
          'bg': const Color(0xFFFEF3C7),
          'color': const Color(0xFFD97706),
        };
      case OrderStatus.preparing:
        return {
          'label': 'PREPARING',
          'bg': const Color(0xFFDBEAFE),
          'color': const Color(0xFF2563EB),
        };
      case OrderStatus.ready:
        return {
          'label': 'READY TO SERVE',
          'bg': const Color(0xFFD1FAE5),
          'color': const Color(0xFF059669),
        };
      case OrderStatus.served:
        return {
          'label': 'SERVED',
          'bg': AppColors.slate100,
          'color': AppColors.slate500,
        };
      case OrderStatus.billed:
        return {
          'label': 'BILLED',
          'bg': const Color(0xFFFEF3C7),
          'color': const Color(0xFFD97706),
        };
      case OrderStatus.paid:
        return {
          'label': 'PAID',
          'bg': const Color(0xFFD1FAE5),
          'color': const Color(0xFF059669),
        };
      default:
        return {
          'label': 'PLACED',
          'bg': AppColors.slate100,
          'color': AppColors.slate500,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();
    final order = provider.findById(widget.orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Not Found')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final config = _getConfig(order.status);

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          // Header
          Container(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: [
                    PremiumBackButton(
                      label: 'Back',
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.table,
                            style: AppTheme.serif(
                              size: 24,
                              weight: FontWeight.w900,
                              color: AppColors.white,
                            ),
                          ),
                          Text(
                            order.orderNumber,
                            style: AppTheme.sans(
                              size: 12,
                              color: AppColors.gold,
                            ),
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
                        color: config['bg'] as Color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        config['label'] as String,
                        style: AppTheme.sans(
                          size: 11,
                          weight: FontWeight.w800,
                          color: config['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Order summary card
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Summary',
                              style: AppTheme.serif(
                                size: 18,
                                weight: FontWeight.w700,
                                color: AppColors.slate900,
                              ),
                            ),
                            Text(
                              order.time,
                              style: AppTheme.sans(
                                size: 13,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (order.customerName != null) ...[
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'Customer',
                            value: order.customerName!,
                          ),
                          const Divider(height: 20),
                        ],
                        _InfoRow(
                          icon: Icons.table_restaurant_outlined,
                          label: 'Table',
                          value: order.table,
                        ),
                        const Divider(height: 20),
                        _InfoRow(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: order.time,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Items',
                          style: AppTheme.serif(
                            size: 18,
                            weight: FontWeight.w700,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...order.itemsDetails.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item.quantity}x',
                                      style: AppTheme.sans(
                                        size: 12,
                                        weight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: AppTheme.sans(
                                      size: 14,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '₹${(item.quantity * (double.tryParse(item.price) ?? 0)).round()}',
                                  style: AppTheme.sans(
                                    size: 14,
                                    weight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        _TotalRow('Subtotal', '₹${order.subtotal.round()}'),
                        const SizedBox(height: 6),
                        _TotalRow('Tax (5%)', '₹${order.tax.round()}'),
                        const SizedBox(height: 10),
                        Container(height: 1, color: AppColors.slate200),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: AppTheme.sans(
                                size: 16,
                                weight: FontWeight.w800,
                                color: AppColors.slate900,
                              ),
                            ),
                            Text(
                              '₹${order.total.round()}',
                              style: AppTheme.sans(
                                size: 20,
                                weight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons based on status
                  _ActionButtons(order: order, provider: provider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.slate400, size: 18),
        const SizedBox(width: 10),
        Text(label, style: AppTheme.sans(size: 13, color: AppColors.slate500)),
        const Spacer(),
        Text(
          value,
          style: AppTheme.sans(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.slate900,
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;

  const _TotalRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.sans(size: 13, color: AppColors.slate500)),
        Text(
          value,
          style: AppTheme.sans(
            size: 14,
            weight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Order order;
  final OrdersProvider provider;

  const _ActionButtons({required this.order, required this.provider});

  @override
  Widget build(BuildContext context) {
    final token = context.read<StaffAuthProvider>().token;

    if (token == null) {
      return const Center(child: Text("Not authenticated"));
    }

    switch (order.status) {
      case OrderStatus.confirmed:
        return PrimaryButton(
          label: 'Mark as Preparing',
          color: const Color(0xFF2563EB),
          onTap: () => provider.updateOrderStatus(
              order.id, OrderStatus.preparing, token),
        );

      case OrderStatus.preparing:
        return PrimaryButton(
          label: 'Mark as Ready',
          color: const Color(0xFF059669),
          onTap: () =>
              provider.updateOrderStatus(order.id, OrderStatus.ready, token),
        );

      case OrderStatus.ready:
        return PrimaryButton(
          label: 'Mark as Served',
          color: AppColors.slate700,
          onTap: () =>
              provider.updateOrderStatus(order.id, OrderStatus.served, token),
        );

      case OrderStatus.served:
        final role = context.read<StaffAuthProvider>().role;
        if (role == StaffRole.billingStaff) {
          return PrimaryButton(
            label: 'Generate Bill',
            color: AppColors.gold,
            textColor: AppColors.primary,
            onTap: () async {
              await provider.generateBill(order.id, token);
              if (!context.mounted) return;
              context.push('/staff/billing');
            },
          );
        }
        // Serving staff can print bill
        final authUser = context.read<StaffAuthProvider>().user;
        return Column(
          children: [
            PrimaryButton(
              label: 'Print Bill',
              icon: Icons.print_rounded,
              color: AppColors.gold,
              textColor: AppColors.primary,
              onTap: () => PrintingUtils.printOrderBill(
                order,
                restaurantName: authUser?.restaurantName,
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Download as PDF',
              icon: Icons.picture_as_pdf_rounded,
              color: AppColors.primary,
              onTap: () => PrintingUtils.downloadOrderBillPdf(
                order,
                restaurantName: authUser?.restaurantName,
              ),
            ),
          ],
        );

      case OrderStatus.billed:
        final billingRole = context.read<StaffAuthProvider>().role;
        if (billingRole == StaffRole.billingStaff) {
          return Column(
            children: [
              PrimaryButton(
                label: 'Process Payment',
                color: AppColors.primary,
                onTap: () => context.push('/staff/payment/${order.id}'),
              ),
            ],
          );
        }
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }
}
