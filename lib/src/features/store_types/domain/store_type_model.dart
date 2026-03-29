class StoreType {
  final String id;
  final String name;
  final String icon;
  final bool isActive;

  StoreType({
    required this.id,
    required this.name,
    required this.icon,
    required this.isActive,
  });

  factory StoreType.fromJson(Map<String, dynamic> json) {
    return StoreType(
      id: json['_id'],
      name: json['name'],
      icon: json['icon'] ?? 'store',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'icon': icon, 'isActive': isActive};
  }
}
