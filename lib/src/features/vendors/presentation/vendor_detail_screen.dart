import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:company_admin/src/core/widgets/app_snackbar.dart';
import '../data/vendor_repository.dart';
import '../domain/vendor_model.dart';
import 'widgets/add_basic_product_dialog.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  final String vendorId;
  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final vendorAsync = ref.watch(vendorDetailProvider(widget.vendorId));

    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Details')),
      body: vendorAsync.when(
        data: (vendor) {
          if (vendor == null) {
            return const Center(child: Text('Vendor not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (vendor.coverImage != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(vendor.coverImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                _buildHeader(vendor),
                const SizedBox(height: 24),
                _buildInfoSection(vendor),
                const SizedBox(height: 24),

                if (vendor.vendorType == 'basic') ...[
                  _buildBasicVendorControls(vendor),
                  const SizedBox(height: 32),
                ],

                if (vendor.status == 'pending') _buildActionButtons(vendor),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeader(Vendor vendor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: vendor.profileImage != null
              ? NetworkImage(vendor.profileImage!)
              : null,
          child: vendor.profileImage == null
              ? Text(
                  vendor.businessName[0],
                  style: const TextStyle(fontSize: 32),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vendor.businessName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              vendor.businessType,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(vendor.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                vendor.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(vendor.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoSection(Vendor vendor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(Icons.person, 'Owner Name', vendor.ownerName),
            const Divider(),
            _buildInfoRow(Icons.email, 'Email', vendor.email),
            // Add more fields if available in model
          ],
        ),
      ),
    );
  }

  Widget _buildBasicVendorControls(Vendor vendor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Vendor Management',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Global Visibility Toggle
        Card(
          child: SwitchListTile(
            title: const Text('Global Visibility'),
            subtitle: const Text(
              'Show this vendor to all customers regardless of location',
            ),
            value: vendor.isGlobalVisible,
            onChanged: (val) async {
              try {
                await ref
                    .read(vendorRepositoryProvider)
                    .toggleBasicVendorVisibility(vendor.id, val);
                ref.invalidate(vendorDetailProvider(vendor.id));
                // ignore: use_build_context_synchronously
                AppSnackbar.success(context, 'Visibility updated');
              } catch (e) {
                // ignore: use_build_context_synchronously
                AppSnackbar.error(context, 'Error: $e');
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Product Management
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddProductDialog(vendor),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Product'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Products uploaded here will be visible on the customer app.',
                  style: TextStyle(color: Colors.grey),
                ),
                // Ideally list products here, but for now just the upload capability
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddProductDialog(Vendor vendor) async {
    final result = await showDialog(
      context: context,
      builder: (_) => AddBasicProductDialog(vendorId: vendor.id),
    );

    if (result == true) {
      ref.invalidate(vendorDetailProvider(vendor.id));
      // ignore: use_build_context_synchronously
      AppSnackbar.success(context, 'Product added successfully');
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Vendor vendor) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleApprove(vendor),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.check),
            label: const Text('APPROVE'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleReject(vendor),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.close),
            label: const Text('REJECT'),
          ),
        ),
      ],
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

  Future<void> _handleApprove(Vendor vendor) async {
    try {
      await ref.read(vendorRepositoryProvider).approveVendor(vendor.id);
      if (!mounted) return;
      AppSnackbar.success(context, 'Vendor Approved');
      ref.invalidate(vendorsProvider);
      ref.invalidate(vendorDetailProvider(vendor.id));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Error: $e');
    }
  }

  Future<void> _handleReject(Vendor vendor) async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Vendor'),
        content: TextField(
          controller: _reasonController,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog first
              try {
                await ref
                    .read(vendorRepositoryProvider)
                    .rejectVendor(vendor.id, _reasonController.text);
                if (!mounted) return;
                AppSnackbar.success(context, 'Vendor Rejected');
                ref.invalidate(vendorsProvider);
                ref.invalidate(vendorDetailProvider(vendor.id));
                context.pop(); // Go back using State's context
              } catch (e) {
                if (!mounted) return;
                AppSnackbar.error(context, 'Error: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
