import 'package:libtokyo_flutter/libtokyo.dart';
import 'library_entry.dart';
import 'dart:io' as io;

mixin FileManagerLogic<T extends StatefulWidget> on State<T> {
  List<LibraryEntry> libraryEntries = <LibraryEntry>[];
  io.Directory? currentDirectory;

  LibraryEntry? get currentLibrary =>
      currentDirectory == null ? null : LibraryEntry.find(entries: libraryEntries, directory: currentDirectory!);

  String? get libraryTitle => currentLibrary == null ? null : currentLibrary!.titleFor(currentDirectory!);

  @mustCallSuper
  @override
  void initState() {
    super.initState();

    LibraryEntry.genList().then((list) => setState(() {
      libraryEntries = list;
    })).catchError((error) => FlutterError.reportError(FlutterErrorDetails(exception: error)));
  }
}