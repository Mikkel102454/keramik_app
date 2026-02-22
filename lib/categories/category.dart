import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Category {
  static int getCategoryCount(){
    return 5;
  }
  static Category getCategory(int id){
    Category category = Category();
    category.id = id;
    category.title = "new title";
    return category;
  }

  int id = 0;
  String title = "No Title";

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
}