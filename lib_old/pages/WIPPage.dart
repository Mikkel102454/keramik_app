import 'package:flutter/material.dart';
import 'package:kemik_app/features/ceramics/logic/WIPController.dart';
import 'package:kemik_app/pages/PageManager.dart';
import 'package:kemik_app/pages/todo/settings_page.dart';
import 'package:kemik_app/ui/layouts/GridLayout.dart';
import 'package:kemik_app/ui/widgets/CollapsableWidget.dart';
import 'package:kemik_app/ui/widgets/SquareWidget.dart';

import 'CeramicCreatePage.dart';
import 'todo/CeramicPage.dart';

class WIPPage extends StatefulWidget {
  const WIPPage({
    super.key,
  });

  @override
  State<WIPPage> createState() => _WIPPageState();
}

class _WIPPageState extends State<WIPPage>
    with WidgetsBindingObserver {
  final WIPController _controller = WIPController();

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
        title: Text("Work In Progress"),

        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),

          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),

            offset: const Offset(0, kToolbarHeight),

            onSelected: (value) async {
              if (value == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Category?'),
                    content: const Text(
                      'Are you sure you want to delete this category?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  Navigator.pop(context, 1);
                }
              }
            },

            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),

        body: AnimatedBuilder(
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

            child: ListView.builder(
              padding: const EdgeInsets.all(12),

              physics: const AlwaysScrollableScrollPhysics(),

              itemCount: _controller.stages.length,

              itemBuilder: (context, stageIndex) {
                return _buildCategory(context, stageIndex);
              },
            ),
          );
          },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CeramicCreatePage(),
            ),
          );

          if (result == true) {
            setState(() {
              _controller.load();
            });
          }
        },
        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCategory(BuildContext context, int stageIndex) {
    final stage = _controller.stages[stageIndex];
    final stageCeramics = _controller.ceramics.where((c) => c.stage == stage.id).toList();
    final isLastStage = stageIndex == _controller.stages.length - 1;
    final hasChildren = stageCeramics.isNotEmpty;

    List<Widget> cards = stageCeramics.map((ceramic) {
      return SquareWidget(
        title: ceramic.title,
        onTap: () =>
        {
          PageManager.new(context).openPage(CeramicPage(ceramicId: ceramic.id))
        },
      );
    }).toList();

    Widget? children;
    if(hasChildren) {
      if (isLastStage) {
        children = GridLayout(crossAxisCount: 1, scrollDirection: Axis.horizontal, children: cards,);
      }
      else {
        children = GridLayout(
          crossAxisCount: 3,
          children: cards,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        );
      }
    }
    return CollapsableWidget(
      title: stage.title,
      child: children,
    );
  }
}
