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
          content: Text('Failed to send feedback: ${e.toString()}'),
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
          title: const Text('Send Feedback'),
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
                  decoration: const InputDecoration(
                    icon: Icon(Icons.email),
                    hintText: 'E-Mail address',
                    labelText: 'E-Mail',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your E-Mail address';
                    }
                    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value) ? null : 'Not a valid E-Mail address';
                  },
                  onSaved: (value) {
                    setState(() {
                      email = value;
                    });
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.note),
                    labelText: 'Your comments',
                  ),
                  maxLines: null,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your comments';
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
                    child: const Text('Submit feedback'),
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
                              const SnackBar(content: Text(
                                  'Successfully submitted your feedback'))
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