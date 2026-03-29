import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../domain/category_model.dart';

/// Repository for Category CRUD operations
class CategoryRepository {
  /// Fetch all common categories (grouped by businessType)
  Future<List<Category>> fetchCommonCategories(String businessType) async {
    // For admin, we need a "common" endpoint - we'll create a pseudo vendor
    // Actually, we need to get all common categories. Backend returns common + vendor specific
    // Let's use a special endpoint or filter. For now, we'll fetch ALL and filter isCommon
    // We need a backend change or use a workaround

    // Workaround: Hit a known vendor endpoint and filter isCommon from results
    // Better approach: Add admin endpoint. For now, let's add one to backend
    // Actually let's add getAllCommonCategories endpoint

    // For now, let's assume the backend has been updated to support:
    // GET /api/category/common/:businessType
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/category/common/$businessType',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<dynamic> list = data['data'] ?? [];
        return list.map((e) => Category.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load categories: ${response.body}');
  }

  /// Create a new common category (Admin only)
  Future<Category> createCategory({
    required String name,
    required String businessType,
    required bool isCommon,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final uri = Uri.parse(ApiConstants.categories);
    final request = http.MultipartRequest('POST', uri);

    request.fields['name'] = name;
    request.fields['businessType'] = businessType;
    request.fields['isCommon'] = isCommon.toString();

    if (imageBytes != null && imageName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageName,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return Category.fromJson(data['data']);
      }
    }
    throw Exception('Failed to create category: ${response.body}');
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    final url = Uri.parse(ApiConstants.deleteCategory(categoryId));
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }
}

/// Provider for the repository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Provider for fetching common categories by business type
final commonCategoriesProvider = FutureProvider.family<List<Category>, String>((
  ref,
  businessType,
) async {
  final repo = ref.read(categoryRepositoryProvider);
  return repo.fetchCommonCategories(businessType);
});
