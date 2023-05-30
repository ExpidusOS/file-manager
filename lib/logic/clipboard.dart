import 'dart:async';
import 'dart:io' as io;
import 'package:collection/collection.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:path/path.dart' as path;

Future<void> _clipboardCopy(io.FileSystemEntity source, io.FileSystemEntity target) async {
  if (source is io.Directory) {
    final items = await source.list(recursive: true).toList();
    for (final item in items) {
      await _clipboardCopy(item, io.Directory(target.path));
    }
  } else if (source is io.File) {
    await source.copy(path.join(target.path, path.basename(source.path)));
  } else if (source is io.Link) {
    await _clipboardLink(source, target);
  }
}

Future<void> _clipboardMove(io.FileSystemEntity source, io.FileSystemEntity target) async {
  await source.rename(path.join(target.path, path.basename(source.path)));
}

Future<void> _clipboardLink(io.FileSystemEntity source, io.FileSystemEntity target) async {
  await io.Link(source.path).create(path.join(target.path, path.basename(source.path)), recursive: true);
}

Future<void> _clipboardDelete(io.FileSystemEntity source, io.FileSystemEntity target) async {
  await source.delete();
}

enum ClipboardAction {
  copy(_clipboardCopy),
  move(_clipboardMove),
  link(_clipboardLink),
  delete(_clipboardDelete);

  const ClipboardAction(this.run);

  final Future<void> Function(io.FileSystemEntity source, io.FileSystemEntity target) run;
}

class ClipboardEntry {
  const ClipboardEntry({
    required this.entry,
    required this.action,
  });
  const ClipboardEntry.copy(this.entry) : action = ClipboardAction.copy;
  const ClipboardEntry.move(this.entry) : action = ClipboardAction.move;
  const ClipboardEntry.link(this.entry) : action = ClipboardAction.link;
  const ClipboardEntry.delete(this.entry) : action = ClipboardAction.delete;

  final io.FileSystemEntity entry;
  final ClipboardAction action;

  Future<void> run(io.FileSystemEntity target) => action.run(entry, target);
}

class ClipboardProcState {
  const ClipboardProcState({
    required this.current,
    required this.count,
    required this.entry,
  });

  final int current;
  final int count;
  final ClipboardEntry entry;
}

class Clipboard extends ChangeNotifier {
  final List<ClipboardEntry> _items = [];
  UnmodifiableListView<ClipboardEntry> get items => UnmodifiableListView(_items);

  void add(ClipboardEntry entry) {
    _items.add(entry);
    notifyListeners();
  }

  void clear({ bool notify = true }) {
    _items.clear();
    if (notify) notifyListeners();
  }

  void removeItemForEntry(io.FileSystemEntity entry) {
    _items.removeWhere((e) => e.entry.path == entry.path);
    notifyListeners();
  }

  int countForAction(ClipboardAction action) {
    var count = 0;
    for (final item in _items) {
      if (item.action == action) count++;
    }
    return count;
  }

  bool hasItemForEntry(io.FileSystemEntity entry) {
    for (final item in _items) {
      if (item.entry.path == entry.path) return true;
    }
    return false;
  }

  Stream<ClipboardProcState> run(io.FileSystemEntity target) {
    late final StreamController<ClipboardProcState> controller;
    controller = StreamController(
      onListen: () async {
        var i = 0;
        for (final item in _items) {
          final current = i++;
          await controller.addStream((() async* {
            yield ClipboardProcState(
              current: current,
              count: _items.length,
              entry: item,
            );

            await item.run(target);
          })());
        }

        await controller.close();
      },
    );
    return controller.stream;
  }
}