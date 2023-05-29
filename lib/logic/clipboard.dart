import 'dart:io' as io;
import 'package:collection/collection.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:provider/provider.dart';

Future<void> _clipboardCopy(io.FileSystemEntity source, io.FileSystemEntity target) async {}
Future<void> _clipboardMove(io.FileSystemEntity source, io.FileSystemEntity target) async {}
Future<void> _clipboardLink(io.FileSystemEntity source, io.FileSystemEntity target) async {}

enum ClipboardAction {
  copy(_clipboardCopy),
  move(_clipboardMove),
  link(_clipboardLink);

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

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Stream<ClipboardProcState> run(io.FileSystemEntity target) async* {
    final items = Stream.fromIterable(_items.mapIndexed((i, entry) => ClipboardProcState(current: i, count: _items.length, entry: entry)));
    await for (final item in items) {
      await item.entry.run(target);
      yield item;
    }

    _items.clear();
    notifyListeners();
  }
}