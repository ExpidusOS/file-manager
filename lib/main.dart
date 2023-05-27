import 'package:file_manager/constants.dart';
import 'package:file_manager/logic/error.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:pubspec/pubspec.dart';
import 'dart:io' as io;
import 'logic.dart';
import 'views.dart';

Future<void> _runMain({
  required bool isSentry,
}) async {
  runApp(FileManagerApp(
    isSentry: isSentry,
    pubspec: PubSpec.fromYamlString(await rootBundle.loadString('pubspec.yaml'))
  ));

  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      doWhenWindowReady(() {
        final win = appWindow;
        const initialSize = Size(600, 450);

        win.minSize = initialSize;
        win.size = initialSize;
        win.alignment = Alignment.center;
        win.show();
      });
      break;
    default:
      break;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  final prefs = await SharedPreferences.getInstance();

  if (sentryDsn.isNotEmpty && (prefs.getBool(FileManagerSettings.optInErrorReporting.name) ?? false)) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;

        if (kDebugMode) {
          options.environment = 'debug';
        } else if (kProfileMode) {
          options.environment = 'profile';
        } else if (kReleaseMode) {
          options.environment = 'release';
        }
      },
      appRunner: () => _runMain(isSentry: true).catchError((error, trace) => handleError(error, trace: trace)),
    );
  } else {
    await _runMain(isSentry: false);
  }
}

class FileManagerApp extends StatefulWidget {
  const FileManagerApp({ super.key, required this.isSentry, required this.pubspec });

  final bool isSentry;
  final PubSpec pubspec;

  @override
  State<FileManagerApp> createState() => _FileManagerApp();

  static Future<void> reload(BuildContext context) => context.findAncestorStateOfType<_FileManagerApp>()!.reload();
  static bool isSentryOnContext(BuildContext context) => context.findAncestorWidgetOfExactType<FileManagerApp>()!.isSentry;
  static PubSpec getPubSpec(BuildContext context) => context.findAncestorWidgetOfExactType<FileManagerApp>()!.pubspec;
}

class _FileManagerApp extends State<FileManagerApp> {
  late SharedPreferences preferences;
  ColorScheme? colorScheme;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) => setState(() {
      preferences = prefs;
      _loadSettings();
    })).catchError((error, trace) {
      handleError(error, trace: trace);
    });
  }

  void _loadSettings() {
    colorScheme = ColorScheme.values.asNameMap()[preferences.getString(FileManagerSettings.colorScheme.name) ?? 'night'];
  }

  Future<void> reload() async {
    await preferences.reload();
    setState(() => _loadSettings());
  }

  @override
  Widget build(BuildContext context) =>
      TokyoApp(
        colorScheme: colorScheme,
        title: 'Flutter Demo',
        navigatorObservers: widget.isSentry ? [
          SentryNavigatorObserver(),
        ] : null,
        home: LibraryView(
          currentDirectory: LibraryEntry.defaultEntry == null ? io.Directory.current : LibraryEntry.defaultEntry!.entry,
        ),
      );
}