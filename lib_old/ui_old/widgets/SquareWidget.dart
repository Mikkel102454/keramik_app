import 'package:flutter/material.dart';

class SquareWidget extends StatelessWidget {
  final String? title;
  final String? imageUri;
  final VoidCallback? onTap;

  const SquareWidget({
    super.key,
    this.title,
    this.imageUri,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),

        child: Container(
          width: double.infinity,

          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),

            image: imageUri != null
                ? DecorationImage(
              image: NetworkImage(imageUri!),
              fit: BoxFit.cover,
            ) : null,
          ),

          alignment: Alignment.center,

          child: Container(
            padding: const EdgeInsets.all(8),
            color: imageUri != null
                ? Colors.black.withOpacity(0.4)
                : Colors.transparent,

            child: Text(
              title ?? "",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}