import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_provider.dart';

// Riverpod providers
final walletProviderInstance = ChangeNotifierProvider(
  (ref) => WalletProvider(),
);

class WalletListScreen extends ConsumerStatefulWidget {
  const WalletListScreen({super.key});

  @override
  ConsumerState<WalletListScreen> createState() => _WalletListScreenState();
}

class _WalletListScreenState extends ConsumerState<WalletListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProviderInstance).fetchAllWallets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(walletProviderInstance);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(walletProviderInstance).fetchAllWallets(),
          ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(WalletProvider provider) {
    if (provider.isLoading && provider.wallets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.wallets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(provider.error!),
            ElevatedButton(
              onPressed: () => provider.fetchAllWallets(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.wallets.isEmpty) {
      return const Center(child: Text('No vendor wallets found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.wallets.length,
      itemBuilder: (context, index) {
        final wallet = provider.wallets[index];
        final isLowBalance = wallet.balance < 100;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isLowBalance
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: Icon(
                Icons.account_balance_wallet,
                color: isLowBalance ? Colors.red : Colors.green,
              ),
            ),
            title: Text(
              wallet.vendorName ??
                  'Vendor ${wallet.vendorId.substring(0, 6)}...',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(wallet.mobile ?? 'No contact'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${wallet.balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isLowBalance ? Colors.red : Colors.green,
                  ),
                ),
                if (isLowBalance)
                  const Text(
                    'Low Balance',
                    style: TextStyle(color: Colors.red, fontSize: 10),
                  ),
              ],
            ),
            onTap: () => _showRechargeDialog(context, wallet.vendorId),
          ),
        );
      },
    );
  }

  void _showRechargeDialog(BuildContext context, String vendorId) {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recharge Wallet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                hintText: 'Minimum ₹100',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Monthly recharge',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, _) {
              final provider = ref.watch(walletProviderInstance);
              return ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final amount =
                            double.tryParse(amountController.text) ?? 0;
                        if (amount < 100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Minimum recharge is ₹100'),
                            ),
                          );
                          return;
                        }

                        final success = await provider.rechargeWallet(
                          vendorId: vendorId,
                          amount: amount,
                          description: descriptionController.text.isNotEmpty
                              ? descriptionController.text
                              : null,
                        );

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Recharged ₹$amount successfully!'
                                    : provider.error ?? 'Recharge failed',
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      },
                child: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Recharge'),
              );
            },
          ),
        ],
      ),
    );
  }
}
