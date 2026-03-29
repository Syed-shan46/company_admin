import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:company_admin/src/features/notifications/data/notification_repository.dart';
import 'package:company_admin/src/features/vendors/data/vendor_repository.dart';
import 'package:company_admin/src/features/vendors/domain/vendor_model.dart';
import 'package:company_admin/src/core/widgets/app_snackbar.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyBroadcast = GlobalKey<FormState>();
  final _formKeyPromo = GlobalKey<FormState>();

  // Broadcast Controllers
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // Promo Controllers
  final _promoContentController = TextEditingController();
  Vendor? _selectedVendor;
  String _targetAudience = 'all'; // 'all' or 'followers'

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _promoContentController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    if (!_formKeyBroadcast.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(notificationRepositoryProvider)
          .sendBroadcast(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
          );
      if (!mounted) return;
      AppSnackbar.success(context, 'Broadcast sent successfully!');
      _titleController.clear();
      _bodyController.clear();
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.error(context, 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPromo() async {
    if (!_formKeyPromo.currentState!.validate()) return;
    if (_selectedVendor == null) {
      AppSnackbar.warning(context, 'Please select a restaurant');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(notificationRepositoryProvider)
          .sendVendorPromotion(
            vendorId: _selectedVendor!.id,
            content: _promoContentController.text.trim(),
            target: _targetAudience,
          );
      if (!mounted) return;
      AppSnackbar.success(
        context,
        'Promotion sent to $_targetAudience users successfully!',
      );
      // Reset form (optional, maybe keep vendor selected)
      _promoContentController.clear();
      // Keep vendor selected for convenience or clear it?
      // User might want to send another to same vendor.
    } catch (e) {
      if (!context.mounted) return;
      AppSnackbar.error(context, 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'App Notification', icon: Icon(Icons.notifications)),
            Tab(text: 'Vendor Promotion', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildBroadcastTab(), _buildPromoTab()],
            ),
    );
  }

  Widget _buildBroadcastTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyBroadcast,
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message Body',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _sendBroadcast,
                icon: const Icon(Icons.send),
                label: const Text('Send to All Users'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoTab() {
    final vendorsAsync = ref.watch(vendorsProvider('approved'));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKeyPromo,
        child: SingleChildScrollView(
          // Added scroll view
          child: Column(
            children: [
              vendorsAsync.when(
                data: (vendors) => Autocomplete<Vendor>(
                  displayStringForOption: (Vendor v) => v.businessName,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '') {
                      return const Iterable<Vendor>.empty();
                    }
                    return vendors.where((Vendor option) {
                      return option.businessName.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (Vendor selection) {
                    setState(() {
                      _selectedVendor = selection;
                    });
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          decoration: InputDecoration(
                            labelText: 'Search Restaurant',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _selectedVendor != null
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : null,
                            helperText: _selectedVendor != null
                                ? 'Selected: ${_selectedVendor!.businessName}'
                                : null,
                          ),
                        );
                      },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading vendors: $err'),
              ),
              const SizedBox(height: 16),
              if (_selectedVendor != null)
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.store,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(
                      _selectedVendor!.businessName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('This restaurant will be promoted'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedVendor = null;
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _targetAudience,
                decoration: const InputDecoration(
                  labelText: 'Target Audience',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(
                    value: 'followers',
                    child: Text('Followers Only'),
                  ),
                ],
                onChanged: (v) => setState(() => _targetAudience = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _promoContentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Promotion Content / Offer Details',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.campaign),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _sendPromo,
                  icon: const Icon(Icons.notifications_active),
                  label: Text(
                    'Promote to ${_targetAudience == 'all' ? 'All Users' : 'Followers'}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
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
