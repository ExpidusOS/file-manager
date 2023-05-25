import 'package:flutter/foundation.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
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

class FileManagerApp extends StatelessWidget {
  const FileManagerApp({ super.key });

  @override
  Widget build(BuildContext context) =>
      TokyoApp(
      title: 'Flutter Demo',
      home: LibraryView(
        currentDirectory: LibraryEntry.defaultEntry == null ? io.Directory.current : LibraryEntry.defaultEntry!.entry,
      ),
    );
}
