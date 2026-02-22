import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Category {
  static int getCategoryCount(){
    return 5;
  }

  int _id = 0;
  String _title = "No Title";

  Widget draw(BuildContext context) {
    return InkWell(
      onTap: () {
        print("Clicked category: $id");
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
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

  int get id => _id;

  set id(int value) {
    _id = value;
  }

  String get title => _title;

  set title(String value) {
    _title = value;
  }
}