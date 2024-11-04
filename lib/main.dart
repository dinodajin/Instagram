import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:instagram/firebase_options.dart';
import 'package:instagram/pages/feed_page.dart';
import 'package:instagram/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InstagramApp());
}

class InstagramApp extends StatelessWidget {
  const InstagramApp({super.key});

  @override
  Widget build(BuildContext context) {
    // FirebaseAuth로부터 현재 로그인한 사용자 정보를 가져옵니다.
    final User? user = FirebaseAuth.instance.currentUser;

    Widget homePage;
    if (user == null) {
      // 만약 사용자가 로그인하지 않은 상태라면 `로그인 페이지(LoginPage)`를 보여줍니다.
      homePage = LoginPage();
    } else {
      // 만약 사용자가 로그인한 상태라면 `홈 페이지(FeedPage)`를 보여줍니다.
      homePage = FeedPage();
    }

    return MaterialApp(
      title: 'Instagram',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pinkAccent,
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: homePage,
    );
  }
}
