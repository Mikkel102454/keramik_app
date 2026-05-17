import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/clay_dto.dart';
import 'package:ceramic_app/objects/glaze_dto.dart';
import 'package:ceramic_app/objects/stage_dto.dart';
import 'package:ceramic_app/repositories/clay_repository.dart';
import 'package:ceramic_app/repositories/glaze_repository.dart';
import 'package:ceramic_app/repositories/stage_repository.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_create/ceramic_create_page.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_view/ceramic_view_page.dart';
import 'package:ceramic_app/ui/pages/notification/notification_controller_page.dart';
import 'package:ceramic_app/ui/widgets/v2/accordion_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:flutter/material.dart';

@RoutePage()
class NotificationPage extends StatefulWidget {
  const NotificationPage({
    super.key,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with WidgetsBindingObserver {
  final NotificationControllerPage _controller = NotificationControllerPage();

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
        title: const Text("Chats"),
        actions: [
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
                child: Text(
                  "Error: ${_controller.error}",
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _controller.load();
              },

              child: _pageContent(
                _controller,
              ),
            );
          },
        ),
      ),

      bottomNavigationBar:
      const NavigationWidget(
        currentPage:
        NavigationPage.notifications,
      ),
    );
  }

  SingleChildScrollView _pageContent(NotificationControllerPage controller) {
    return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),

        padding: const EdgeInsets.all(16),

        child: Column(
        )
    );
  }
}