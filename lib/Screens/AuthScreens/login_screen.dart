import 'package:flutter/material.dart';

class LoginActivity extends StatelessWidget {
  const LoginActivity({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 150.0),
            const Text(
              '로그인',
              style: TextStyle(fontSize: 36.0, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50.0),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '학번 또는 아이디',
                hintStyle: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 30.0),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: '비밀번호',
                hintStyle: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
              ),
              child: const Text('로그인', style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
              ),
              child: const Text('회원가입', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
