import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_select/ceramic_create/ceramic_create_page.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_select/ceramic_view/ceramic_view_page.dart';
import 'package:ceramic_app/ui/widgets/CollapseGridLayout.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/ui/widgets/SquareWidget.dart';
import 'package:ceramic_app/ui/widgets/GridLayout.dart';
import 'my_clays_page_controller.dart';

@RoutePage()
class MyClaysPage extends StatefulWidget {
  const MyClaysPage({
    super.key,
  });

  @override
  State<MyClaysPage> createState() => _MyClaysPageState();
}

class _MyClaysPageState extends State<MyClaysPage>
    with WidgetsBindingObserver {
  final MyClaysPageController _controller = MyClaysPageController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Keramik App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),

      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, _) {
            if (_controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (_controller.error != null) {
              return Center(
                child: Text("Error: ${_controller.error}"),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _controller.load();
              },
              child: Container()
            );
          },
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
        },
        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
