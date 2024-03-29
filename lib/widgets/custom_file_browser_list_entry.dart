import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:file_manager/logic.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io' as io;

class CustomFileBrowserListEntry extends FileBrowserListEntry {
  const CustomFileBrowserListEntry({
    super.key,
    required super.entry,
    super.onTap,
    this.longPress,
  });

  final void Function(String value)? longPress;

  @override
  Widget build(BuildContext context) {
    Widget? iconWidget = null;
    if (showIcon) {
      if (entry is io.File) {
        iconWidget = Icon(
          Icons.fileLines,
          size: iconSize,
        );
      } else if (entry is io.Directory) {
        iconWidget = Icon(
          Icons.folder,
          size: iconSize,
        );
      } else if (entry is io.Link) {
        iconWidget = Icon(
          Icons.link,
          size: iconSize,
        );
      }
    }

    void _handleError(BuildContext context, Object e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.genericErrorMessage(e.toString())),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          )
      );
    }

    final locale = Localizations.localeOf(context).toString().replaceAll('-', '_');
    return FutureBuilder<io.FileStat>(
      future: entry.stat(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text(snapshot.error!.toString());
        if (snapshot.hasData) {
          final data = snapshot.data!;
          final RenderBox tile = context.findRenderObject()! as RenderBox;
          final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;

          final RelativeRect position = RelativeRect.fromRect(
            Rect.fromPoints(
              tile.localToGlobal(Offset.zero, ancestor: overlay),
              tile.localToGlobal(tile.size.bottomRight(Offset.zero), ancestor: overlay),
            ),
            Offset.zero & overlay.size,
          );

          return ListTile(
            leading: iconWidget,
            title: Text(path.basename(entry.path)),
            subtitle: Text(DateFormat.yMd().add_jm().format(data.changed)),
            trailing: entry is io.File ? Text(filesize(data.size)) : null,
            enabled: enabled,
            selected: selected,
            onTap: onTap,
            onLongPress: () =>
              showMenu<String>(
                context: context,
                position: position,
                items: [
                  PopupMenuItem(
                    value: 'copy',
                    child: Text(AppLocalizations.of(context)!.libraryItemActionCopy),
                  ),
                  PopupMenuItem(
                    value: 'move',
                    child: Text(AppLocalizations.of(context)!.libraryItemActionMove),
                  ),
                  PopupMenuItem(
                    value: 'link',
                    child: Text(AppLocalizations.of(context)!.libraryItemActionLink),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(AppLocalizations.of(context)!.libraryItemActionDelete),
                  ),
                ],
              ).then((value) {
                if (value == 'delete') {
                  entry.delete(recursive: true).catchError((error) => _handleError(context, error));
                } else {}

                if (longPress != null) longPress!(value!);
              }).catchError((error, trace) => handleError(error, trace: trace)),
          );
        }
        return const CircularProgressIndicator();
      }
    );
  }
}
