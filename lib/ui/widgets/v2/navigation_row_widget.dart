import 'package:ceramic_app/ui/widgets/v2/divider_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NavigationRowWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onClick;
  final Widget navigation;
  final bool showTopDivider;

  const NavigationRowWidget({
    super.key,
    required this.text,
    this.onClick,
    required this.navigation,
    this.showTopDivider = false,
  });

  void _handleTap(BuildContext context) {
    if (onClick != null) {
      onClick!();
    }

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => navigation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopDivider)
          Container(
            height: 1,
            color: const Color(0xFFE0E0E0),
          ),

        InkWell(
          onTap: () => _handleTap(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        DividerWidget()
      ],
    );
  }
}