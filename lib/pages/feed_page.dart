import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:instagram/data/post.dart';
import 'package:instagram/pages/login_page.dart';
import 'package:instagram/pages/write_page.dart';
import 'package:instagram/widgets/post_widget.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<Post> _posts = [];
  List<String?> _activeUsers = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _loadActiveUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: const Color(0xFFF1F2F3),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            return _loadPosts();
          },
          child: ListView(
            children: [
              // 현재 인스타그램에 접속한 유저 목록을 보여주는 UI
              _buildActiveUsers(),

              // 인스타그램 피드 카드
              for (final item in _posts)
                PostWidget(
                  item: item,
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Text("로그아웃"),
        onPressed: () async {
          // 로그아웃 처리
          await FirebaseAuth.instance.signOut();

          // 첫 페이지로 이동 (로그인 페이지)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) {
                return LoginPage();
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadPosts() async {
    // FirebaseFirestore로부터 데이터를 받아옵니다.
    final snapshot = await FirebaseFirestore.instance
        .collection("posts")
        .orderBy("createdAt", descending: true)
        // .where("uid", isNotEqualTo: FirebaseAuth.instance.currentUser?.uid) // 나 말고 다른 사람이 올린 글만 보기
        .get();
    final documents = snapshot.docs;

    // FirebaseFirestore로부터 받아온 데이터를 Post 객체로 변환합니다.
    List<Post> posts = [];

    for (final doc in documents) {
      // doc --> Post 객체로 변환
      final data = doc.data();

      final post = Post(
        uid: data["uid"],
        username: data["username"],
        imageUrl: data["imageUrl"],
        description: data["description"],
        createdAt: data["createdAt"],
      );

      // posts에 넣는다.
      posts.add(post);
    }

    // Post 객체를 이용하여 화면을 다시 그립니다.
    setState(() {
      _posts = posts;
    });
  }

  // 접속한 사용자 리스트
  Widget _buildActiveUsers() {
    return Container(
      height: 100,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        children: [
          // 현재 접속한 사용자 수를 Text 위젯으로 보여줍니다.
          Text(
            "현재 접속한\n사용자의 수: ${_activeUsers.length}",
          ),
          for (final userName in _activeUsers) _buildActiveUserCircle(userName),
        ],
      ),
    );
  }

  // 접속한 사용자 동그라미
  Widget _buildActiveUserCircle(String? userName) {
    if (userName == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: 72,
      height: 72,
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Colors.yellow,
            Colors.orangeAccent,
            Colors.redAccent,
            Colors.purpleAccent,
          ],
          stops: [0.1, 0.4, 0.6, 0.9],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF1F2F3),
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: Text(
            userName,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    // remote config에 있는 write_button_red을 참조해서
    // 만약 true: 글쓰기 버튼 색깔 빨강
    // 만약 false: 글쓰기 버튼 색깔 까망

    final bool isWriteButtonRed =
        FirebaseRemoteConfig.instance.getBool("write_button_red");
    return AppBar(
      backgroundColor: const Color(0xFFF1F2F3),
      title: Image.asset(
        'assets/logo2.png',
        width: 120,
      ),
      centerTitle: true,
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Icon(
              Icons.add_box_outlined,
              color: isWriteButtonRed ? Colors.red : Colors.black,
            ),
            onPressed: () async {
              // 글쓰기 페이지로 이동
              await Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) {
                    return WritePage();
                  },
                ),
              );

              // 전체 포스트를 새로고침 해주기
              _loadPosts();
            },
          ),
        ),
      ],
    );
  }

  // 활동 중인 사용자 목록을 받아옵니다.
  void _loadActiveUsers() {
    FirebaseDatabase.instance.ref().child('active_users').onValue.listen(
      (event) {
        // 활성화된 사용자의 이름 목록 값
        final newActiveUsers = List<String?>.from(
          event.snapshot.value as List<dynamic>,
        );

        setState(() {
          _activeUsers = newActiveUsers;
        });
      },
    );
  }
}
