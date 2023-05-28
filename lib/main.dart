import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:pubspec/pubspec.dart';
import 'dart:io' as io;

import 'constants.dart';
import 'logic.dart';
import 'widgets.dart';
import 'views.dart';

Future<void> _runMain({
  required bool isSentry,
  required PubSpec pubspec,
  required List<String> args,
}) async {
  final app = FileManagerApp(
    isSentry: isSentry,
    pubspec: pubspec,
    directory: args.isNotEmpty ? io.Directory(args.first) : null,
  );
  runApp(isSentry ? DefaultAssetBundle(bundle: SentryAssetBundle(), child: app) : app);

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

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final pubspec = PubSpec.fromYamlString(await rootBundle.loadString('pubspec.yaml'));

  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  final prefs = await SharedPreferences.getInstance();

  if (sentryDsn.isNotEmpty && (prefs.getBool(FileManagerSettings.optInErrorReporting.name) ?? false)) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 1.0;
        options.release = 'com.expidusos.file_manager@${pubspec.version!}';

        if (kDebugMode) {
          options.environment = 'debug';
        } else if (kProfileMode) {
          options.environment = 'profile';
        } else if (kReleaseMode) {
          options.environment = 'release';
        }
      },
      appRunner: () => _runMain(
        isSentry: true,
        pubspec: pubspec,
        args: args,
      ).catchError((error, trace) => handleError(error, trace: trace)),
    );
  } else {
    await _runMain(
      isSentry: false,
      pubspec: pubspec,
      args: args,
    );
  }
}

class FileManagerApp extends StatefulWidget {
  const FileManagerApp({
    super.key,
    required this.isSentry,
    required this.pubspec,
    this.directory,
  });

  final bool isSentry;
  final PubSpec pubspec;
  final io.Directory? directory;

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
        title: 'File Manager',
        navigatorObservers: widget.isSentry ? [
          SentryNavigatorObserver(
            setRouteNameAsTransaction: true,
          ),
        ] : null,
        home: LibraryView(
          currentDirectory: widget.directory ?? (LibraryEntry.defaultEntry == null ? io.Directory.current : LibraryEntry.defaultEntry!.entry),
        ),
      );
}