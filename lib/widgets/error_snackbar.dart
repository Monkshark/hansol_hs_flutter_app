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
  } else {
    message = l.error_generic;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
