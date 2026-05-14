import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/users_repository.dart';
import '../domain/user_model.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _searchController.clear();
        _searchQuery = '';
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User & Partner Accounts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              // Beautiful Segmented Selector
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.storefront),
                    text: 'Vendor Partners',
                  ),
                  Tab(
                    icon: Icon(Icons.person_outline),
                    text: 'App Customers',
                  ),
                ],
              ),
              // Robust Search Input
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _tabController.index == 0
                        ? 'Search by Store Owner Name or Mobile...'
                        : 'Search by Customer Name or Mobile...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase().trim();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVendorUsersTab(),
          _buildCustomersTab(),
        ],
      ),
    );
  }

  Widget _buildVendorUsersTab() {
    final usersAsync = ref.watch(vendorUsersListProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(vendorUsersListProvider.future),
      child: usersAsync.when(
        data: (users) {
          // Client-side fuzzy filtering
          final filteredUsers = users.where((u) {
            return u.ownerName.toLowerCase().contains(_searchQuery) ||
                u.mobile.contains(_searchQuery) ||
                u.email.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filteredUsers.isEmpty) {
            return _buildEmptyState(
              _searchQuery.isEmpty
                  ? 'No registered Vendor Users found.'
                  : 'No matches found for "$_searchQuery"',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredUsers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = filteredUsers[index];
              return _buildVendorCard(user);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildCustomersTab() {
    final customersAsync = ref.watch(customersListProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(customersListProvider.future),
      child: customersAsync.when(
        data: (customers) {
          final filteredCustomers = customers.where((c) {
            return c.name.toLowerCase().contains(_searchQuery) ||
                c.mobile.contains(_searchQuery) ||
                c.email.toLowerCase().contains(_searchQuery);
          }).toList();

          if (filteredCustomers.isEmpty) {
            return _buildEmptyState(
              _searchQuery.isEmpty
                  ? 'No registered Customers found.'
                  : 'No matches found for "$_searchQuery"',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredCustomers.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final customer = filteredCustomers[index];
              return _buildCustomerCard(customer);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorState(err.toString()),
      ),
    );
  }

  Widget _buildVendorCard(VendorUser user) {
    final joinedDate = DateFormat('MMM dd, yyyy').format(user.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.indigo[50],
          child: const Icon(Icons.store, color: Colors.indigo),
        ),
        title: Text(
          user.ownerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('${user.mobile} • Role: ${user.role.toUpperCase()}'),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('User ID:', style: TextStyle(color: Colors.grey)),
              Text(user.id, style: const TextStyle(fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Email Contact:', style: TextStyle(color: Colors.grey)),
              Text(user.email),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Joined Platform:', style: TextStyle(color: Colors.grey)),
              Text(joinedDate),
            ],
          ),
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmation(
                  userId: user.id,
                  userName: user.ownerName,
                  isVendor: true,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: BorderSide(color: Colors.red[100]!),
                ),
                icon: const Icon(Icons.delete_forever, size: 18),
                label: const Text('CASCADE DELETE ACCOUNT'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    final joinedDate = DateFormat('MMM dd, yyyy').format(customer.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal[50],
          child: const Icon(Icons.person, color: Colors.teal),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                customer.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (customer.isVerified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: const Text(
                  'VERIFIED',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ),
          ],
        ),
        subtitle: Text(customer.mobile),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Customer ID:', style: TextStyle(color: Colors.grey)),
              Text(customer.id, style: const TextStyle(fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Email Contact:', style: TextStyle(color: Colors.grey)),
              Text(customer.email),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Registered On:', style: TextStyle(color: Colors.grey)),
              Text(joinedDate),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmation(
                  userId: customer.id,
                  userName: customer.name,
                  isVendor: false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: BorderSide(color: Colors.red[100]!),
                ),
                icon: const Icon(Icons.delete_forever, size: 18),
                label: const Text('DELETE CUSTOMER'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation({
    required String userId,
    required String userName,
    required bool isVendor,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, anim1, anim2) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              const SizedBox(width: 10),
              const Text('⚠️ DANGER ZONE'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you absolutely certain you want to wipe out "$userName"?',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (isVendor)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '🚨 POWER CASCADE WIPE ENABLED:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'This will trigger the backend relational purge. The following associated items will be DELETED FOREVER:\n'
                          '• Store Registration & Profiles\n'
                          '• Operating Status & Active Stories\n'
                          '• Menus, Addons, & Inventory Lists\n'
                          '• Complete Wallets & Balance History\n'
                          '• Reviews, Orders, & Assigned Deliveries\n\n'
                          'THIS ACTION IS IRREVERSIBLE!',
                          style: TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  )
                else
                  const Text(
                    'This will delete the customer user profile completely from Getzio systems. They will be logged out and their active session closed.',
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                _executeDeletion(userId, isVendor);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('YES, WIPE COMPLETELY'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeDeletion(String id, bool isVendor) async {
    // Show visual loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Executing Secure Relational Purge...',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final repo = ref.read(usersRepositoryProvider);
    bool success = false;

    try {
      if (isVendor) {
        success = await repo.deleteVendorUser(id);
        if (success) {
          // Trigger list rebuild
          ref.refresh(vendorUsersListProvider);
        }
      } else {
        success = await repo.deleteCustomer(id);
        if (success) {
          ref.refresh(customersListProvider);
        }
      }
    } catch (e) {
      success = false;
    }

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    // Show status banner
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '🎉 Successfully wiped out user and all database relations!'
                : '❌ Error executing relational deletion. Please check API status.',
          ),
          backgroundColor: success ? Colors.green[700] : Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Failed to load account data.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.refresh(vendorUsersListProvider);
                ref.refresh(customersListProvider);
              },
              child: const Text('RETRY LOADING'),
            ),
          ],
        ),
      ),
    );
  }
}
