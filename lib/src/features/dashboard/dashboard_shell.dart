import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:company_admin/src/features/auth/data/auth_repository.dart';
import 'package:company_admin/src/features/dashboard/data/dashboard_repository.dart'
    as package_dashboard;
import 'package:company_admin/src/features/vendors/data/vendor_repository.dart'
    as package_vendors;

import 'package:company_admin/src/core/services/socket_service.dart';

class DashboardShell extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  @override
  void initState() {
    super.initState();
    // Initialize socket for real-time updates now that we are logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminSocketService().initSocket();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Basic Shell with Drawer/AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Admin Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                context.go('/');
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Vendors'),
              onTap: () {
                context.go('/vendors');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Store Types'),
              onTap: () {
                context.go('/store-types');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              onTap: () {
                context.go('/categories');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Users'),
              onTap: () {
                context.go('/users');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('Orders'),
              onTap: () {
                context.go('/orders');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () {
                context.go('/notifications');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Support'),
              onTap: () {
                context.go('/support');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Vendor Wallets'),
              onTap: () {
                context.go('/wallet');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Banners'),
              onTap: () {
                context.go('/banners');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: widget.child,
    );
  }
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(package_dashboard.dashboardStatsProvider);
    // Fetch pending vendors for homescreen list
    final pendingVendorsAsync = ref.watch(
      package_vendors.vendorsProvider('pending'),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(package_dashboard.dashboardStatsProvider.future),
            ref.refresh(package_vendors.vendorsProvider('pending').future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Overview',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            statsAsync.when(
              data: (stats) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildSummaryGrid(
                                  context,
                                  stats,
                                  crossAxisCount: 4,
                                  ratio: 1.4,
                                ),
                              ),
                            ],
                          )
                        : _buildSummaryGrid(
                            context,
                            stats,
                            crossAxisCount: 2,
                            ratio: 1.2,
                          );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error loading stats: $err')),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Approvals',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => context.go('/vendors'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            pendingVendorsAsync.when(
              data: (vendors) {
                if (vendors.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No pending approvals needed.'),
                    ),
                  );
                }
                // Show only first 5
                final limit = vendors.length > 5 ? 5 : vendors.length;
                final displayVendors = vendors.sublist(0, limit);

                return Column(
                  children: displayVendors.map((vendor) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: vendor.profileImage != null
                              ? NetworkImage(vendor.profileImage!)
                              : null,
                          child: vendor.profileImage == null
                              ? Text(
                                  vendor.businessName.isNotEmpty
                                      ? vendor.businessName[0]
                                      : '?',
                                )
                              : null,
                        ),
                        title: Text(
                          vendor.businessName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${vendor.ownerName} • ${vendor.businessType}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => context.go('/vendors/${vendor.id}'),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) =>
                  Text('Error loading pending vendors: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    Map<String, dynamic> stats, {
    required int crossAxisCount,
    double ratio = 1.0,
  }) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: ratio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          'Total Users',
          '${stats['totalUsers'] ?? 0}',
          Colors.indigo,
          Icons.people,
          onTap: () => GoRouter.of(context).go('/users'),
        ),
        _buildStatCard(
          'Total Orders',
          '${stats['totalOrders'] ?? 0}',
          Colors.teal,
          Icons.shopping_bag,
          onTap: () => GoRouter.of(context).go('/orders'),
        ),
        _buildStatCard(
          'Pending Orders',
          '${stats['pendingOrders'] ?? 0}',
          Colors.deepOrange,
          Icons.timelapse,
          onTap: () => GoRouter.of(context).go('/orders'),
        ),
        _buildStatCard(
          'Total Vendors',
          '${stats['totalVendors'] ?? 0}',
          Colors.blue,
          Icons.store,
          onTap: () => GoRouter.of(context).go('/vendors'),
        ),
        _buildStatCard(
          'Pending Vendors',
          '${stats['pendingVendors'] ?? 0}',
          Colors.orange,
          Icons.pending_actions,
          onTap: () => GoRouter.of(context).go('/vendors'),
        ),
        _buildStatCard(
          'Active Vendors',
          '${stats['approvedVendors'] ?? 0}',
          Colors.green,
          Icons.check_circle,
          onTap: () => GoRouter.of(context).go('/vendors'),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
