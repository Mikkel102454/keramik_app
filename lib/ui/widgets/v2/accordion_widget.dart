import 'package:flutter/material.dart';

class AccordionWidget extends StatefulWidget {
  final VoidCallback? onInteract;
  final String title;
  final Icon? icon;
  final Widget child;
  final bool initiallyExpanded;

  /// Count bubble
  final bool showCount;
  final int count;

  const AccordionWidget({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.onInteract,
    this.initiallyExpanded = false,

    this.showCount = false,
    this.count = 0,
  });

  @override
  State<AccordionWidget> createState() =>
      _AccordionWidgetState();
}

class _AccordionWidgetState
    extends State<AccordionWidget>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();

    _isExpanded =
        widget.initiallyExpanded;
  }

  void _toggleAccordion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    widget.onInteract?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: _toggleAccordion,

          child: Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),

            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Color(0xFFE0E0E0),
                ),
              ),
            ),

            child: Row(
              children: [
                AnimatedRotation(
                  turns:
                  _isExpanded ? 0.5 : 0,

                  duration:
                  const Duration(
                    milliseconds: 200,
                  ),

                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                  ),
                ),

                const SizedBox(width: 10),

                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 12),
                ],

                Expanded(
                  child: Text(
                    widget.title,

                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),

                if (widget.showCount)
                  Container(
                    width: 42,
                    height: 24,

                    alignment: Alignment.center,

                    decoration:
                    const BoxDecoration(
                      color:
                      Color(0xFFE5E5EA),

                      borderRadius:
                      BorderRadius.all(
                        Radius.circular(999),
                      ),
                    ),

                    child: Text(
                      widget.count.toString(),

                      style:
                      const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (widget.count > 0)
          AnimatedCrossFade(
            firstChild:
            const SizedBox.shrink(),

            secondChild: Container(
              width: double.infinity,

              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),

              child: widget.child,
            ),

            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,

            duration:
            const Duration(
              milliseconds: 150,
            ),
          ),
      ],
    );
  }
}