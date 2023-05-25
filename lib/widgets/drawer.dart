import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:file_manager/logic.dart';
import 'dart:io' as io;

class FileManagerDrawer extends StatefulWidget {
  const FileManagerDrawer({
    super.key,
    this.currentDirectory,
  });

  final io.Directory? currentDirectory;

  @override
  State<FileManagerDrawer> createState() => _FileManagerDrawerState();
}

class _FileManagerDrawerState extends State<FileManagerDrawer> with FileManagerLogic<FileManagerDrawer> {
  @override
  void initState() {
    super.initState();

    currentDirectory = widget.currentDirectory;
  }

  @override
  Widget build(BuildContext context) =>
      Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurface,
              ),
              child: libraryTitle != null ? Text(libraryTitle!) : null,
            ),
            ...(libraryEntries..sort((a, b) => a.title.compareTo(b.title))).map((entry) => entry.build(context)),
          ],
        ),
      );
}