import 'package:flutter/material.dart';
import 'package:footer/footer.dart';
import 'package:footer/footer_view.dart';

class AppFooter extends StatefulWidget {
  const AppFooter({super.key});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  int selectedIndex = 0;

  Widget navIcon(String path, int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          selectedIndex = index;
        });
      },
      icon: Image.asset(
        path,
        width: 26,
        color: selectedIndex == index ? Colors.black : Colors.grey,
      ),
    );
  }

  @override
  FooterView build(BuildContext context) {
    return FooterView(
      children:<Widget>[
        new Padding(
          padding: new EdgeInsets.only(top:200.0),
          child: Center(
            child: new Text('Scrollable View'),
          ),
        ),
      ],
      footer: new Footer(
        child: Text('I am a Customizable footer!!'),
        padding: EdgeInsets.all(10.0),
      ),
      flex: 1, //default flex is 2
    );
  }
}