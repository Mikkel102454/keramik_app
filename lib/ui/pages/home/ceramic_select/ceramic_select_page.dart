import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_select/ceramic_create/ceramic_create_page.dart';
import 'package:ceramic_app/ui/pages/home/ceramic_select/ceramic_view/ceramic_view_page.dart';
import 'package:ceramic_app/ui/widgets/CollapseGridLayout.dart';
import 'package:flutter/material.dart';

import 'package:ceramic_app/ui/widgets/SquareWidget.dart';
import 'package:ceramic_app/ui/widgets/GridLayout.dart';
import 'ceramic_select_page_controller.dart';

class CeramicSelectPage extends StatefulWidget {
  const CeramicSelectPage({
    super.key,
  });

  @override
  State<CeramicSelectPage> createState() => _CeramicSelectPageState();
}

class _CeramicSelectPageState extends State<CeramicSelectPage>
    with WidgetsBindingObserver {
  final CeramicSelectPageController _controller = CeramicSelectPageController();

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
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _openCreatePage();
        },
        child: const Icon(Icons.add),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _openCreatePage() async {
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
  }

  Future<void> _openViewPage(CeramicDto ceramic) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CeramicViewPage(ceramic: ceramic, stages: _controller.stages,),
      ),
    );

    if (result == true) {
      setState(() {
        _controller.load();
      });
    }
  }

  Widget _buildCategory(BuildContext context, int stageIndex) {
    final stage = _controller.stages[stageIndex];
    final stageCeramics = _controller.ceramics.where((c) => c.stage == stage.id).toList();
    final isLastStage = stageIndex == _controller.stages.length - 1;
    final hasChildren = stageCeramics.isNotEmpty;

    List<Widget> cards = stageCeramics.map((ceramic) {
      return SquareWidget(
        title: ceramic.title,
        onTap: () => {
          _openViewPage(ceramic)
        },
      );
    }).toList();

    Widget? children;
    if(hasChildren) {
      if (isLastStage) {
        children = GridLayout(
          crossAxisCount: 3,
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cards,
        );
      }
      else {
        children = SizedBox(
          height: 130,
          child: GridLayout(
            crossAxisCount: 1,
            scrollDirection: Axis.horizontal,
            //shrinkWrap: true,
            children: cards,
          ),
        );
      }
    }
    return CollapseGridLayout(
      title: stage.title,
      child: children,
    );
  }
}
