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
            SizedBox(height: 150.0),
            Text(
              '로그인',
              style: TextStyle(fontSize: 36.0, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50.0),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '학번 또는 아이디',
                hintStyle: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 30.0),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                hintText: '비밀번호',
                hintStyle: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: () {},
              child: Text('로그인', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                primary: Colors.white,
                onPrimary: Colors.black,
              ),
            ),
            SizedBox(height: 30.0),
            ElevatedButton(
              onPressed: () {},
              child: Text('회원가입', style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                primary: Colors.white,
                onPrimary: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
