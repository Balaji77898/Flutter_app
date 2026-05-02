import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../contexts/auth_provider.dart';
import '../contexts/tables_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<StaffAuthProvider>().token;
      if (token != null) {
        context.read<TablesProvider>().fetchTables(token);
      }
    });
  }

  _TableDisplayConfig _getStatusConfig(TableModel table) {
    if (table.status == TableStatus.occupied) {
      return const _TableDisplayConfig(
        bg: Color(0xFFEFF6FF),
        textColor: Color(0xFF2563EB),
        label: 'Occupied',
        icon: Icons.people_rounded,
        gradient: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        cardBorder: Color(0xFFBFDBFE),
      );
    } else {
      return _TableDisplayConfig(
        bg: const Color(0xFFF0FDF4),
        textColor: const Color(0xFF16A34A),
        label: 'Available',
        icon: Icons.check_circle_rounded,
        gradient: const [Color(0xFF34D399), Color(0xFF10B981)],
        cardBorder: const Color(0xFFBBF7D0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablesProvider = context.watch<TablesProvider>();
    final allTables = tablesProvider.tables;

    final filters = [
      {'id': 'all', 'label': 'All', 'count': allTables.length},
      {
        'id': 'available',
        'label': 'Available',
        'count': allTables.where((t) => t.status == TableStatus.available).length,
      },
      {
        'id': 'occupied',
        'label': 'Occupied',
        'count': allTables.where((t) => t.status == TableStatus.occupied).length,
      },
    ];

    List<TableModel> filteredTables;
    if (_activeFilter == 'all') {
      filteredTables = allTables;
    } else if (_activeFilter == 'available') {
      filteredTables =
          allTables.where((t) => t.status == TableStatus.available).toList();
    } else {
      filteredTables =
          allTables.where((t) => t.status == TableStatus.occupied).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          const PageHeader(
            title: 'Floor Plan',
            subtitle: 'Real-time Table Status',
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 768;

                // Filter buttons
                Widget filterList = isWide
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: filters
                            .map((f) => _buildFilterButton(f, isWide: true))
                            .toList(),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: filters
                              .map((f) => Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child:
                                        _buildFilterButton(f, isWide: false),
                                  ))
                              .toList(),
                        ),
                      );

                Widget content = tablesProvider.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48),
                          child: CircularProgressIndicator(
                              color: AppColors.primary),
                        ),
                      )
                    : filteredTables.isEmpty
                        ? const EmptyState(
                            icon: Icons.grid_view_rounded,
                            title: 'No tables found',
                            subtitle: 'Try a different filter',
                          )
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isWide
                                  ? (constraints.maxWidth >= 1024 ? 3 : 2)
                                  : 1,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              mainAxisExtent: 110,
                            ),
                            itemCount: filteredTables.length,
                            itemBuilder: (context, index) {
                              final table = filteredTables[index];
                              final config = _getStatusConfig(table);
                              return _TableCard(table: table, config: config)
                                  .animate(
                                      delay: Duration(
                                          milliseconds: index * 60))
                                  .fade(duration: 350.ms)
                                  .slideY(
                                      begin: 0.1,
                                      end: 0,
                                      duration: 350.ms,
                                      curve: Curves.easeOutQuad);
                            },
                          );

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Sidebar Filter Panel
                                Container(
                                  width: 240,
                                  margin: const EdgeInsets.only(right: 24),
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                        color: AppColors.slate100),
                                    boxShadow: AppShadows.card,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'VIEW OPTIONS',
                                        style: AppTextStyles.overline(
                                          color: AppColors.slate400,
                                          size: 10,
                                        ).copyWith(letterSpacing: 1.5),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                filterList,
                                const SizedBox(height: 20),
                                content,
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

  Widget _buildFilterButton(Map<String, dynamic> f, {required bool isWide}) {
    final isActive = _activeFilter == f['id'];
    final count = f['count'] as int;

    return Padding(
      padding: isWide ? const EdgeInsets.only(bottom: 8) : EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => setState(() => _activeFilter = f['id'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive ? null : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? AppColors.goldDark.withValues(alpha: 0.3)
                  : AppColors.slate200,
            ),
            boxShadow: isActive ? AppShadows.goldGlow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                f['label'] as String,
                style: AppTheme.sans(
                  size: 13,
                  weight: FontWeight.w700,
                  color: isActive ? AppColors.primary : AppColors.slate700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: AppTheme.sans(
                    size: 11,
                    weight: FontWeight.w800,
                    color: isActive ? AppColors.primary : AppColors.slate500,
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

// ─── Table Card ────────────────────────────────────────────────────────────
class _TableCard extends StatelessWidget {
  final TableModel table;
  final _TableDisplayConfig config;

  const _TableCard({required this.table, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: config.cardBorder),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Left gradient strip
          Container(
            width: 5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: config.gradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: config.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      config.icon,
                      size: 24,
                      color: config.textColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          table.name,
                          style: AppTextStyles.label(
                            color: AppColors.slate900,
                            size: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          config.label,
                          style: AppTheme.sans(
                            size: 12,
                            weight: FontWeight.w600,
                            color: config.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status pill on right
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: config.bg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: config.textColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: config.textColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          config.label,
                          style: AppTheme.sans(
                            size: 11,
                            weight: FontWeight.w700,
                            color: config.textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Table Display Config ──────────────────────────────────────────────────
class _TableDisplayConfig {
  final Color bg;
  final Color textColor;
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final Color cardBorder;

  const _TableDisplayConfig({
    required this.bg,
    required this.textColor,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.cardBorder,
  });
}
