import 'package:libtokyo_flutter/libtokyo.dart';
import 'form_dialog.dart';

class SingleTextInputFormDialog extends StatefulWidget {
  const SingleTextInputFormDialog({
    super.key,
    this.title,
    this.validator,
    this.decoration,
    this.buildActions,
  });

  final Widget? title;
  final String? Function(String? text)? validator;
  final InputDecoration? decoration;
  final List<Widget> Function(BuildContext context, GlobalKey<FormState> formState, String? value)? buildActions;

  @override
  State<SingleTextInputFormDialog> createState() => _SingleTextInputFormDialogState();
}

class _SingleTextInputFormDialogState extends State<SingleTextInputFormDialog> {
  String? value;

  @override
  Widget build(BuildContext context) =>
      FormDialog(
        title: widget.title,
        buildContent: (context, formState) =>
          TextFormField(
            validator: widget.validator,
            decoration: widget.decoration,
            onSaved: (v) => setState(() {
              value = v;
            }),
          ),
        buildActions: widget.buildActions == null ? null
          : (context, formState) => widget.buildActions!(context, formState, value),
      );
}