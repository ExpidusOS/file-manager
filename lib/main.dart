import 'package:libtokyo_flutter/libtokyo.dart';
import 'dart:io' as io;
import 'logic.dart';
import 'views.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({ super.key });

  @override
  Widget build(BuildContext context) =>
      TokyoApp(
      title: 'Flutter Demo',
      home: LibraryView(
        currentDirectory: LibraryEntry.defaultEntry == null ? io.Directory.current : LibraryEntry.defaultEntry!.entry,
      ),
    );
}
