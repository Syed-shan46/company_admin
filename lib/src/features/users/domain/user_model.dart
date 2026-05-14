class VendorUser {
  final String id;
  final String ownerName;
  final String mobile;
  final String email;
  final String role;
  final DateTime createdAt;

  VendorUser({
    required this.id,
    required this.ownerName,
    required this.mobile,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  factory VendorUser.fromJson(Map<String, dynamic> json) {
    return VendorUser(
      id: json['_id'] ?? '',
      ownerName: json['ownerName'] ?? 'N/A',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? 'N/A',
      role: json['role'] ?? 'user',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Customer {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final bool isVerified;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.isVerified,
    required this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Getzio User',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? 'N/A',
      isVerified: json['isVerified'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}
