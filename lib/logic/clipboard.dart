import 'dart:io' as io;

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