class ApiConstants {
  static const String baseUrl = "https://getzio-backend-dev.onrender.com/api";
  static const String imageBaseUrl = "https://getzio-backend-dev.onrender.com";

  // Auth
  static const String login = '$baseUrl/auth/admin/login';

  // Admin - Vendors (matches backend: /api/admin/...)
  static const String adminVendors = '$baseUrl/admin/vendors';
  static String approveVendor(String id) => '$baseUrl/admin/vendor/$id/approve';
  static String rejectVendor(String id) => '$baseUrl/admin/vendor/$id/reject';

  // Basic Vendor Admin Operations
  static String basicVendorVisibility(String vendorId) =>
      '$baseUrl/basic-vendor/$vendorId/visibility';
  static String basicVendorProducts(String vendorId) =>
      '$baseUrl/basic-vendor/$vendorId/products';

  // Dashboard
  static const String dashboardStats = '$baseUrl/admin/stats';

  // Orders (for admin overview)
  // Orders (for admin overview)
  static const String allOrders = '$baseUrl/order/all';

  // Categories (Common Categories for Admin)
  static const String categories = '$baseUrl/category';
  static String categoriesByVendor(String vendorId) =>
      '$baseUrl/category/$vendorId';
  static String deleteCategory(String categoryId) =>
      '$baseUrl/category/$categoryId';

  // Notifications
  static const String sendBroadcast = '$baseUrl/admin/notifications/broadcast';
  static const String sendVendorPromotion =
      '$baseUrl/admin/notifications/vendor-promotion';

  // Support Chat
  static const String allSupportTickets = '$baseUrl/support';
  static String supportTicketById(String ticketId) =>
      '$baseUrl/support/ticket/$ticketId';
  static const String sendSupportReply = '$baseUrl/support';
  static String closeSupportTicket(String ticketId) =>
      '$baseUrl/support/$ticketId/close';

  // Wallet
  static const String allWallets = '$baseUrl/wallet';
  static String vendorWallet(String vendorId) => '$baseUrl/wallet/$vendorId';
  static const String rechargeWallet = '$baseUrl/wallet/recharge';
  static String walletTransactions(String vendorId) =>
      '$baseUrl/wallet/$vendorId/transactions';
}
