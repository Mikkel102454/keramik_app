import 'package:flutter/material.dart';
import 'package:kemik_app/pages/todo/ceramic_page.dart';

class CeramicCard {
  final int id;
  final String title;

  CeramicCard(this.id, this.title);

  Widget draw(BuildContext context, VoidCallback onReturn) {
    return InkWell(
      onTap: () async {
        final changed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => CeramicPage(
              ceramicId: id,
            ),
          ),
        );

        // If something changed → refresh parent
        if (changed == true) {
          onReturn();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}