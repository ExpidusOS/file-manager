import 'package:libtokyo_flutter/libtokyo.dart';

class FormDialog extends StatefulWidget {
  const FormDialog({
    super.key,
    this.title,
    this.buildContent,
    this.buildActions,
  });

  final Widget? title;
  final Widget Function(BuildContext context, GlobalKey<FormState> formState)? buildContent;
  final List<Widget> Function(BuildContext context, GlobalKey<FormState> formState)? buildActions;

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) =>
      AlertDialog(
        title: widget.title,
        content: widget.buildContent == null ? null : Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.always,
          onChanged: () {
            _formKey.currentState!.save();
          },
          child: widget.buildContent!(context, _formKey),
        ),
        actions: widget.buildActions == null ? null : widget.buildActions!(context, _formKey),
      );
}