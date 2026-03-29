import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class Wallet {
  final String vendorId;
  final double balance;
  final DateTime? updatedAt;
  final String? vendorName;
  final String? mobile;

  Wallet({
    required this.vendorId,
    required this.balance,
    this.updatedAt,
    this.vendorName,
    this.mobile,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendorId'];
    String? vendorName;
    String? mobile;
    String vendorId = '';

    if (vendor is Map<String, dynamic>) {
      vendorId = vendor['_id'] ?? '';
      final vendorUser = vendor['vendorUserId'];
      if (vendorUser is Map<String, dynamic>) {
        vendorName = vendorUser['ownerName'];
        mobile = vendorUser['mobile'];
      }
    } else if (vendor is String) {
      vendorId = vendor;
    }

    return Wallet(
      vendorId: vendorId,
      balance: (json['balance'] ?? 0).toDouble(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      vendorName: vendorName,
      mobile: mobile,
    );
  }
}

class WalletTransaction {
  final String id;
  final String vendorId;
  final String type;
  final double amount;
  final String description;
  final double balanceAfter;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.vendorId,
    required this.type,
    required this.amount,
    required this.description,
    required this.balanceAfter,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['_id'] ?? '',
      vendorId: json['vendorId'] is Map
          ? json['vendorId']['_id']
          : json['vendorId'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      balanceAfter: (json['balanceAfter'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class WalletProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Wallet> _wallets = [];
  List<Wallet> get wallets => _wallets;

  List<WalletTransaction> _transactions = [];
  List<WalletTransaction> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchAllWallets() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConstants.allWallets);
      if (response != null && response['data'] != null) {
        _wallets = (response['data'] as List)
            .map((json) => Wallet.fromJson(json))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Wallet?> fetchVendorWallet(String vendorId) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.vendorWallet(vendorId),
      );
      if (response != null && response['data'] != null) {
        return Wallet.fromJson(response['data']);
      }
    } catch (e) {
      _error = e.toString();
    }
    return null;
  }

  Future<bool> rechargeWallet({
    required String vendorId,
    required double amount,
    String? description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.post(
        ApiConstants.rechargeWallet,
        body: {
          'vendorId': vendorId,
          'amount': amount,
          'description': description ?? 'Admin recharge',
        },
      );

      if (response != null && response['success'] == true) {
        await fetchAllWallets(); // Refresh list
        return true;
      } else {
        _error = response?['message'] ?? 'Recharge failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransactions(String vendorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        ApiConstants.walletTransactions(vendorId),
      );
      if (response != null && response['data'] != null) {
        final data = response['data'];
        if (data['transactions'] != null) {
          _transactions = (data['transactions'] as List)
              .map((json) => WalletTransaction.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
