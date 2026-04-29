import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/exceptions.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';

void showErrorSnackbar(BuildContext context, Object error) {
  final l = AppLocalizations.of(context)!;
  String message;
  if (error is NetworkException) {
    message = l.error_network;
  } else if (error is ApiException) {
    message = l.error_loadFailed;
  } else if (error is AuthException) {
    message = l.common_loginRequired;
  } else if (error is AppException) {
    message = error.message;
  } else if (error is FirebaseException) {
    final code = error.code;
    final detail = error.message ?? '';
    message = '${l.error_generic} ($code${detail.isNotEmpty ? ': $detail' : ''})';
  } else {
    message = '${l.error_generic} (${error.runtimeType})';
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
  );
}
