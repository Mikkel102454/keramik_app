import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CollapsableWidget extends StatefulWidget {
  final String title;
  final Widget? child;
  const CollapsableWidget({
    super.key,
    required this.title,
    this.child
  });

  @override
  State<CollapsableWidget> createState() => _CollapsableWidgetState();
}
class _CollapsableWidgetState extends State<CollapsableWidget> {
  late final String title;
  late final Widget? child;

  @override
  void initState() {
    super.initState();

    title = widget.title;
    child = widget.child;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 8), // tighter

      child: child != null
          ? Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),

          child: ExpansionTile(
            tilePadding:
            const EdgeInsets.symmetric(
                horizontal: 8),

            childrenPadding:
            const EdgeInsets.only(bottom: 8),

            title: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            children: [
              child!
            ],
          )
      )
      : Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 6),

        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}