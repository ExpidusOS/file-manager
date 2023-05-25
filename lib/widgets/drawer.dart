import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:file_manager/logic.dart';
import 'package:file_manager/views.dart';
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
              child: currentLibrary != null ? Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(currentLibrary!.iconData),
                  const SizedBox(width: 15),
                  Text(currentLibrary!.title),
                ],
              ) : null,
            ),
            ...LibraryEntry.buildWidgets(libraryEntries, context),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsView(),
                )
              ),
            ),
          ],
        ),
      );
}