import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../data/banner_repository.dart';

class BannersScreen extends ConsumerStatefulWidget {
  const BannersScreen({super.key});

  @override
  ConsumerState<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends ConsumerState<BannersScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isUploading = true);
      try {
        await ref
            .read(bannerRepositoryProvider)
            .uploadBanner(File(pickedFile.path));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner uploaded successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error uploading banner: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteBanner(String id, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this banner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(bannerRepositoryProvider).deleteBanner(id, imageUrl);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting banner: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Banners')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadImage,
        icon: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add_photo_alternate),
        label: Text(_isUploading ? 'Uploading...' : 'Add Banner'),
      ),
      body: bannersAsync.when(
        data: (banners) {
          if (banners.isEmpty) {
            return const Center(child: Text('No banners uploaded yet.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Adjust based on screen size if needed
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 16 / 9,
            ),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      banner.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (ctx, error, stackTrace) =>
                          const Center(child: Icon(Icons.error)),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        onPressed: () =>
                            _deleteBanner(banner.id, banner.imageUrl),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
