import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:company_admin/src/core/widgets/app_snackbar.dart';
import '../data/vendor_repository.dart';
import '../domain/vendor_model.dart';

class VendorListScreen extends ConsumerStatefulWidget {
  const VendorListScreen({super.key});

  @override
  ConsumerState<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends ConsumerState<VendorListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Management'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          VendorListTab(status: 'pending'),
          VendorListTab(status: 'approved'),
          VendorListTab(status: 'rejected'),
        ],
      ),
    );
  }
}

class VendorListTab extends ConsumerWidget {
  final String status;
  const VendorListTab({super.key, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch provider
    final vendorsAsync = ref.watch(vendorsProvider(status));

    return vendorsAsync.when(
      data: (vendors) {
        if (vendors.isEmpty) {
          return Center(child: Text('No $status vendors found'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () => GoRouter.of(context).go('/vendors/${vendor.id}'),
                leading: CircleAvatar(
                  backgroundImage: vendor.profileImage != null
                      ? NetworkImage(vendor.profileImage!)
                      : null,
                  child: vendor.profileImage == null
                      ? Text(vendor.businessName[0].toUpperCase())
                      : null,
                ),
                title: Text(
                  vendor.businessName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${vendor.ownerName} • ${vendor.businessType}'),
                    Text(
                      'Email: ${vendor.email}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: status == 'pending'
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            onPressed: () =>
                                _approveVendor(context, ref, vendor),
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () =>
                                _rejectVendor(context, ref, vendor),
                            tooltip: 'Reject',
                          ),
                        ],
                      )
                    : Chip(
                        label: Text(vendor.status.toUpperCase()),
                        backgroundColor: _getStatusColor(vendor.status),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _approveVendor(
    BuildContext context,
    WidgetRef ref,
    Vendor vendor,
  ) async {
    try {
      await ref.read(vendorRepositoryProvider).approveVendor(vendor.id);
      ref.invalidate(vendorsProvider(status)); // Refresh list
      ref.invalidate(vendorsProvider('approved')); // Refresh active list too
      if (context.mounted) {
        AppSnackbar.success(context, 'Vendor Approved');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Error: $e');
      }
    }
  }

  Future<void> _rejectVendor(
    BuildContext context,
    WidgetRef ref,
    Vendor vendor,
  ) async {
    // Show Dialog to get reason
    // For MVP, just hardcode rejection
    try {
      await ref
          .read(vendorRepositoryProvider)
          .rejectVendor(vendor.id, "Documents missing");
      ref.invalidate(vendorsProvider(status));
      ref.invalidate(vendorsProvider('rejected'));
      if (context.mounted) {
        AppSnackbar.success(context, 'Vendor Rejected');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Error: $e');
      }
    }
  }
}
