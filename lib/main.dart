import 'package:file_manager/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' as io;
import 'logic.dart';
import 'views.dart';

void main() {
  runApp(const FileManagerApp());

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

class FileManagerApp extends StatefulWidget {
  const FileManagerApp({ super.key });

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
        home: LibraryView(
          currentDirectory: LibraryEntry.defaultEntry == null ? io.Directory.current : LibraryEntry.defaultEntry!.entry,
        ),
      );
}