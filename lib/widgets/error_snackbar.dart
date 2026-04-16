import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/exceptions.dart';

void showErrorSnackbar(BuildContext context, Object error) {
  String message;
  if (error is NetworkException) {
    message = '네트워크 연결을 확인해주세요';
  } else if (error is ApiException) {
    message = '데이터를 불러올 수 없습니다';
  } else if (error is AuthException) {
    message = '로그인이 필요합니다';
  } else if (error is AppException) {
    message = error.message;
  } else {
    message = '오류가 발생했습니다';
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
