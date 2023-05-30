import 'package:file_manager/constants.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Feedback extends StatefulWidget {
  const Feedback({ super.key, required this.id });

  final FileManagerFeedbackID id;

  @override
  State<StatefulWidget> createState() => _FeedbackState();
}

class _FeedbackState extends State<Feedback> {
  final _formKey = GlobalKey<FormState>();
  String? email;
  String? comments;

  void _handleError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.feedbackSubmitFail(e.toString())),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        )
    );
  }

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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.always,
            onChanged: () {
              _formKey.currentState!.save();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.email),
                    hintText: AppLocalizations.of(context)!.feedbackFieldHintEmail,
                    labelText: AppLocalizations.of(context)!.feedbackFieldLabelEmail,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.feedbackFieldEmptyEmail;
                    }
                    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value) ? null : AppLocalizations.of(context)!.feedbackFieldInvalidEmail;
                  },
                  onSaved: (value) {
                    setState(() {
                      email = value;
                    });
                  },
                ),
                TextFormField(
                  decoration: InputDecoration(
                    icon: const Icon(Icons.note),
                    labelText: AppLocalizations.of(context)!.feedbackFieldLabelComments,
                  ),
                  maxLines: null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.feedbackFieldEmptyComments;
                    }
                    return null;
                  },
                  onSaved: (value) {
                    setState(() {
                      comments = value;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    child: Text(AppLocalizations.of(context)!.feedbackSubmit),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        Sentry.captureUserFeedback(
                          SentryUserFeedback(
                            eventId: await widget.id.id,
                            name: email,
                            email: email,
                            comments: comments,
                          )
                        ).then((value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.feedbackSubmitSuccess))
                          );

                          Navigator.of(context).popUntil((route) =>
                          !(route.settings.name ?? '').contains('Feedback'));
                        }).catchError((error) => _handleError(context, error));
                      }
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      );
}