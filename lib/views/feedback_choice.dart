import 'package:file_manager/constants.dart';
import 'package:file_manager/views/feedback.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide Feedback;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FeedbackChoice extends StatelessWidget {
  const FeedbackChoice({ super.key });
  
  @override
  Widget build(BuildContext context) =>
      Scaffold(
        windowBar: WindowBar.shouldShow(context) ? PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight / 2),
          child: MoveWindow(
            child: WindowBar(
              leading: Image.asset('assets/imgs/icon.png'),
              title: Text(AppLocalizations.of(context)!.applicationTitle),
              onMinimize: () => appWindow.minimize(),
              onMaximize: () => appWindow.maximize(),
              onClose: () => appWindow.close(),
            ),
          ),
        ) : null,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.feedbackSend),
        ),
        body: ListView(
          children: FileManagerFeedbackID.values.map((id) => ListTile(
            title: Text(id.onGenerateTitle(context)),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Feedback(id: id),
                settings: const RouteSettings(name: 'Feedback'),
              )
            ),
          )).map((child) => child is Divider ? child : ListTileTheme(
            tileColor: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
            shape: Theme.of(context).cardTheme.shape,
            contentPadding: Theme.of(context).cardTheme.margin,
            child: child
          )).toList(),
        ),
      );
}