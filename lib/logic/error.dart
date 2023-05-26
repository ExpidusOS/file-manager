import 'package:file_manager/constants.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> isSentryEnabled() async {
  try {
    const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    final prefs = await SharedPreferences.getInstance();

    return sentryDsn.isNotEmpty &&
        (prefs.getBool(FileManagerSettings.optInErrorReporting.name) ?? false);
  } catch (error, trace) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: trace,
    ));
    return false;
  }
}

void handleError(Object e, { StackTrace? trace, bool sendFlutter = !kReleaseMode, }) {
  trace ??= StackTrace.current;

  isSentryEnabled().then((isSentry) {
    if (isSentry) {
      Sentry.captureException(
        e,
        stackTrace: trace,
      ).catchError((error, trace) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: error,
          stack: trace,
        ));
      });

      if (!sendFlutter) {
        return;
      }
    }

    FlutterError.reportError(FlutterErrorDetails(
      exception: e,
      stack: trace,
    ));
  });
}