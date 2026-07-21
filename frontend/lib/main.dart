import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Nhận thông báo ngầm: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Trạng thái cấp quyền thông báo: ${settings.authorizationStatus}');

      String? token = await messaging.getToken();
      debugPrint("FCM Token thiết bị Android: $token");

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Nhận thông báo khi đang mở app: ${message.notification?.title}');
      });
    } else {
      debugPrint("Đang chạy trên Edge (Web): Đã bỏ qua FCM Token tự động để tránh lỗi Web Push.");
    }
  } catch (e) {
    debugPrint('Lỗi khởi tạo FCM: $e');
  }

  runApp(const GradeAIApp());
}

class GradeAIApp extends StatelessWidget {
  const GradeAIApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hệ thống chấm thi PE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      navigatorObservers: <NavigatorObserver>[observer],
      home: const LoginScreen(),
    );
  }
}