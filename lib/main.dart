import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' hide Clipboard;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide ColorScheme;
import 'package:libtokyo/libtokyo.dart' hide TokyoApp;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec/pubspec.dart';
import 'package:provider/provider.dart';
import 'dart:io' as io;

import 'constants.dart';
import 'logic.dart';
import 'widgets.dart';
import 'views.dart';

final kCommitHash = (const String.fromEnvironment('COMMIT_HASH', defaultValue: 'AAAAAAA')).substring(0, 7);

Future<void> _runMain({
  required bool isSentry,
  required bool isFirstRun,
  required PubSpec pubspec,
  required List<String> args,
}) async {
  final app = FileManagerApp(
    isSentry: isSentry,
    isFirstRun: isFirstRun,
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
  final pinfo = await PackageInfo.fromPlatform();

  final pubspec = PubSpec.fromYamlString(await rootBundle.loadString('pubspec.yaml')).copy(
    version: Version.parse("${pinfo.version}+$kCommitHash"),
  );

  const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  final prefs = await SharedPreferences.getInstance();
  final isFirstRun = prefs.getBool(FileManagerSettings.firstRun.name) ?? true;

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
        isFirstRun: isFirstRun,
        pubspec: pubspec,
        args: args,
      ).catchError((error, trace) => handleError(error, trace: trace)),
    );
  } else {
    await _runMain(
      isSentry: false,
      isFirstRun: isFirstRun,
      pubspec: pubspec,
      args: args,
    );
  }
}

class FileManagerApp extends StatefulWidget {
  const FileManagerApp({
    super.key,
    required this.isFirstRun,
    required this.isSentry,
    required this.pubspec,
    this.directory,
  });

  final bool isFirstRun;
  final bool isSentry;
  final PubSpec pubspec;
  final io.Directory? directory;

  @override
  State<FileManagerApp> createState() => _FileManagerApp();

  static Future<void> reload(BuildContext context) => context.findAncestorStateOfType<_FileManagerApp>()!.reload();
  static bool isSentryOnContext(BuildContext context) => context.findAncestorWidgetOfExactType<FileManagerApp>()!.isSentry;
  static PubSpec getPubSpec(BuildContext context) => context.findAncestorWidgetOfExactType<FileManagerApp>()!.pubspec;
  static bool isFirstRunOnContext(BuildContext context) => context.findAncestorStateOfType<_FileManagerApp>()!.isFirstRun
    ?? context.findAncestorWidgetOfExactType<FileManagerApp>()!.isFirstRun;

  static bool popFirstRun(BuildContext context) {
    final state = context.findAncestorStateOfType<_FileManagerApp>()!;
    final value = state.isFirstRun ?? context.findAncestorWidgetOfExactType<FileManagerApp>()!.isFirstRun;
    if (value) {
      state.isFirstRun = false;
      state.preferences.setBool(FileManagerSettings.firstRun.name, state.isFirstRun!);
    }
    return value;
  }
}

class _FileManagerApp extends State<FileManagerApp> {
  late SharedPreferences preferences;
  bool? isFirstRun;
  ColorScheme? colorScheme;

  @override
  void initState() {
    super.initState();

    isFirstRun = widget.isFirstRun;

    SharedPreferences.getInstance().then((prefs) => setState(() {
      preferences = prefs;
      _loadSettings();
    })).catchError((error, trace) {
      handleError(error, trace: trace);
    });
  }

  void _loadSettings() {
    colorScheme = ColorScheme.values.asNameMap()[preferences.getString(FileManagerSettings.colorScheme.name) ?? 'night'];
    isFirstRun = preferences.getBool(FileManagerSettings.firstRun.name) ?? widget.isFirstRun;
  }

  Future<void> reload() async {
    await preferences.reload();
    setState(() => _loadSettings());
  }

  @override
  Widget build(BuildContext context) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Clipboard()),
      ],
      child: TokyoApp(
        themeMode: colorScheme == ColorScheme.day ? ThemeMode.light : ThemeMode.dark,
        colorScheme: colorScheme,
        colorSchemeDark: colorScheme,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.applicationTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: widget.isSentry ? [
          SentryNavigatorObserver(
            setRouteNameAsTransaction: true,
          ),
        ] : null,
        home: Builder(
          builder: (context) =>
            LibraryView(
              currentDirectory: widget.directory ?? (LibraryEntry.getDefaultEntry(context) == null ? io.Directory.current : LibraryEntry.getDefaultEntry(context)!.entry),
              parentContext: context,
            ),
        ),
      ),
    );
}
