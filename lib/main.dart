import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint(
      "Firebase init failed (ignore if not using Firebase features yet): $e",
    );
  }

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize socket for real-time updates (Moved to a more appropriate place or handled lazily)
  // AdminSocketService().initSocket();
  runApp(const ProviderScope(child: CompanyAdminApp()));
}
