import 'package:file_manager/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'dart:io' as io;
import 'logic.dart';
import 'views.dart';

void _runMain({
  required bool isSentry,
}) {
  runApp(FileManagerApp(isSentry: isSentry));

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

  const sentryDsn = FileManagerBuildConfig.sentryDsn;
  final perfs = await SharedPreferences.getInstance();

  if (sentryDsn.isSet && (perfs.getBool(FileManagerSettings.optInErrorReporting.name) ?? false)) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn.value;
      },
      appRunner: () => _runMain(isSentry: true),
    );
  } else {
    _runMain(isSentry: false);
  }
}

class FileManagerApp extends StatefulWidget {
  const FileManagerApp({ super.key, required this.isSentry });

  final bool isSentry;

  @override
  State<FileManagerApp> createState() => _FileManagerApp();

  static Future<void> reload(BuildContext context) => context.findAncestorStateOfType<_FileManagerApp>()!.reload();
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
    })).catchError((error) => FlutterError.reportError(FlutterErrorDetails(exception: error)));
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