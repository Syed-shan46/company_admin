import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:company_admin/src/core/widgets/app_snackbar.dart';
import '../data/store_type_repository.dart';
import '../domain/store_type_model.dart';
import 'package:google_fonts/google_fonts.dart';

class StoreTypesScreen extends ConsumerStatefulWidget {
  const StoreTypesScreen({super.key});

  @override
  ConsumerState<StoreTypesScreen> createState() => _StoreTypesScreenState();
}

class _StoreTypesScreenState extends ConsumerState<StoreTypesScreen> {
  @override
  Widget build(BuildContext context) {
    final storeTypesAsync = ref.watch(storeTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Types')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context),
        child: const Icon(Icons.add),
      ),
      body: storeTypesAsync.when(
        data: (storeTypes) {
          if (storeTypes.isEmpty) {
            return const Center(child: Text('No store types found.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(storeTypesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: storeTypes.length,
              itemBuilder: (context, index) {
                final type = storeTypes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade100,
                      child: Icon(_getIconData(type.icon), color: Colors.blue),
                    ),
                    title: Text(
                      type.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      type.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: type.isActive ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: type.isActive,
                          onChanged: (val) => _toggleStatus(type, val),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddEditDialog(context, storeType: type);
                            } else if (value == 'delete') {
                              _confirmDelete(context, type);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {StoreType? storeType}) {
    showDialog(
      context: context,
      builder: (ctx) => _StoreTypeDialog(
        storeType: storeType,
        onSave: () => ref.refresh(storeTypesProvider.future),
      ),
    );
  }

  Future<void> _toggleStatus(StoreType type, bool isActive) async {
    try {
      await ref
          .read(storeTypeRepositoryProvider)
          .updateStoreType(type.id, type.name, type.icon, isActive);
      await ref.refresh(storeTypesProvider.future);
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (mounted) AppSnackbar.error(context, 'Failed to update status: $e');
    }
  }

  Future<void> _confirmDelete(BuildContext context, StoreType type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Store Type?'),
        content: Text('Are you sure you want to delete "${type.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(storeTypeRepositoryProvider).deleteStoreType(type.id);
        await ref.refresh(storeTypesProvider.future);
        // ignore: use_build_context_synchronously
        if (mounted) AppSnackbar.success(context, 'Store type deleted');
      } catch (e) {
        // ignore: use_build_context_synchronously
        if (mounted) AppSnackbar.error(context, 'Failed to delete: $e');
      }
    }
  }

  IconData _getIconData(String iconName) {
    // Map string names to IconData (simplified map)
    switch (iconName) {
      case 'store':
        return Icons.store;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_grocery_store':
        return Icons.local_grocery_store;
      default:
        return Icons.store;
    }
  }
}

class _StoreTypeDialog extends ConsumerStatefulWidget {
  final StoreType? storeType;
  final VoidCallback onSave;

  const _StoreTypeDialog({this.storeType, required this.onSave});

  @override
  ConsumerState<_StoreTypeDialog> createState() => _StoreTypeDialogState();
}

class _StoreTypeDialogState extends ConsumerState<_StoreTypeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _iconController; // Treating icon as text for now
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.storeType?.name ?? '');
    _iconController = TextEditingController(
      text: widget.storeType?.icon ?? 'store',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final name = _nameController.text.trim();
      final icon = _iconController.text.trim();

      if (widget.storeType == null) {
        await ref.read(storeTypeRepositoryProvider).createStoreType(name, icon);
      } else {
        await ref
            .read(storeTypeRepositoryProvider)
            .updateStoreType(
              widget.storeType!.id,
              name,
              icon,
              widget.storeType!.isActive,
            );
      }
      widget.onSave();
      // ignore: use_build_context_synchronously
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (mounted) AppSnackbar.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.storeType != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Store Type' : 'Add Store Type'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _iconController,
              decoration: const InputDecoration(
                labelText: 'Icon Name (e.g., store)',
                hintText: 'Material Icon name',
              ),
              validator: (val) =>
                  val == null || val.isEmpty ? 'Icon is required' : null,
            ),
          ],
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
              : Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }
}
