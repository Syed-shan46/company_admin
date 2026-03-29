import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import '../domain/banner_model.dart';

final bannerRepositoryProvider = Provider((ref) => BannerRepository());

final bannersProvider = StreamProvider<List<PromoBanner>>((ref) {
  final repo = ref.watch(bannerRepositoryProvider);
  return repo.watchBanners();
});

class BannerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'banners';

  Stream<List<PromoBanner>> watchBanners() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PromoBanner.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Future<void> uploadBanner(File imageFile) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final ref = _storage.ref().child('banners/$fileName');

      // Upload
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // Save to Firestore
      await _firestore.collection(_collection).add({
        'imageUrl': downloadUrl,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to upload banner: $e');
    }
  }

  Future<void> deleteBanner(String id, String imageUrl) async {
    try {
      // Delete from Firestore
      await _firestore.collection(_collection).doc(id).delete();

      // Delete from Storage (try/catch in case it doesn't exist)
      try {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      } catch (_) {
        // Ignore storage delete errors (maybe already gone)
      }
    } catch (e) {
      throw Exception('Failed to delete banner: $e');
    }
  }
}
