import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:company_admin/src/core/widgets/app_snackbar.dart';
import '../data/category_repository.dart';
import '../domain/category_model.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _businessTypes = ['grocery', 'restaurant', 'supermarket'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _businessTypes.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _businessTypes
              .map((type) => Tab(text: type.toUpperCase()))
              .toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _businessTypes.map((type) {
          return _CategoryList(businessType: type);
        }).toList(),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AddCategoryDialog(
        businessTypes: _businessTypes,
        currentType: _businessTypes[_tabController.index],
        onCategoryAdded: () {
          // Refresh the current tab
          ref.invalidate(
            commonCategoriesProvider(_businessTypes[_tabController.index]),
          );
        },
      ),
    );
  }
}

class _CategoryList extends ConsumerWidget {
  final String businessType;

  const _CategoryList({required this.businessType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(commonCategoriesProvider(businessType));

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No categories for ${businessType.toUpperCase()}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to add a common category',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(commonCategoriesProvider(businessType));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                onDelete: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Category?'),
                      content: Text(
                        'Are you sure you want to delete "${category.name}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await ref
                          .read(categoryRepositoryProvider)
                          .deleteCategory(category.id);
                      ref.invalidate(commonCategoriesProvider(businessType));
                      if (context.mounted) {
                        AppSnackbar.success(context, 'Category deleted');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.error(context, 'Error: $e');
                      }
                    }
                  }
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(commonCategoriesProvider(businessType)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onDelete;

  const _CategoryCard({required this.category, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: category.image != null && category.image!.isNotEmpty
              ? Image.network(
                  category.image!,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.category),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.category),
                ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: category.isCommon
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category.isCommon ? 'COMMON' : 'VENDOR',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: category.isCommon
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Colors.orange.shade700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              category.businessType.toUpperCase(),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _AddCategoryDialog extends ConsumerStatefulWidget {
  final List<String> businessTypes;
  final String currentType;
  final VoidCallback onCategoryAdded;

  const _AddCategoryDialog({
    required this.businessTypes,
    required this.currentType,
    required this.onCategoryAdded,
  });

  @override
  ConsumerState<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<_AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _selectedType;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = pickedFile.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(categoryRepositoryProvider)
          .createCategory(
            name: _nameController.text.trim(),
            businessType: _selectedType,
            isCommon: true,
            imageBytes: _imageBytes,
            imageName: _imageName,
          );
      widget.onCategoryAdded();
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'Category created successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Common Category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 32,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add Image',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Business Type Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Business Type',
                  border: OutlineInputBorder(),
                ),
                items: widget.businessTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
