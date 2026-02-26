import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;
  final String? title;

  const RatingWidget({
    Key? key,
    required this.rating,
    required this.onChanged,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (title != null)
          Text(
            title!,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        if (title != null) const SizedBox(width: 8),
        ...List.generate(5, (index) {
          return IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => onChanged(index + 1),
            icon: Icon(
              Icons.star,
              color: index < rating ? Colors.green : Colors.grey,
            ),
          );
        }),
      ],
    );
  }
}
