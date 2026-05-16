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
import 'package:ceramic_app/ui/widgets/v2/accordion_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/square_widget.dart';
import 'package:flutter/material.dart';

import 'home_page_controller.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver {
  final HomePageController _controller = HomePageController();

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
        title: const Text("Ceramics"),
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

      floatingActionButton:
      FloatingActionButton(
        onPressed: () async {
          List<StageDto> stages = await StageRepository.getStages();
          List<ClayDto> clayTypes = await ClayRepository.getClayTypes();
          List<GlazeDto> glazes = await GlazeRepository.getGlazes();

          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => CeramicCreatePage(
                  stages: stages,
                  clayTypes: clayTypes,
                  glazes: glazes
              ),
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

      bottomNavigationBar:
      const NavigationWidget(
        currentPage:
        NavigationPage.home,
      ),
    );
  }

  ListView _pageContent(HomePageController controller) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: controller.stages.length,
      itemBuilder: (context, stageIndex) {
        List<CeramicDto> ceramics = controller.ceramics.where((ceramic) => ceramic.stageId == controller.stages[stageIndex].id).toList();
        return AccordionWidget(
          showCount: true,
          count: ceramics.length,
          title: controller.stages[stageIndex].title,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
                ceramics.length,
                    (index) =>
                    SquareWidget(
                      fontColor: Colors.black,
                      backgroundColor: Colors.grey.shade300,
                      title: ceramics[index].title,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      imageUri: ceramics[index].images.isNotEmpty ? ceramics[index].images[0].uri : null,
                      width: 118,
                      height: 118,
                      onPressed: () async {
                        List<StageDto> stages = await StageRepository.getStages();
                        List<ClayDto> clayTypes = await ClayRepository.getClayTypes();
                        List<GlazeDto> glazes = await GlazeRepository.getGlazes();

                        final result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CeramicViewPage(
                                    ceramic: ceramics[index],
                                    stages: stages,
                                    clayTypes: clayTypes,
                                    glazes: glazes),
                          ),
                        );

                        if (result == true) {
                          setState(() {
                            _controller.load();
                          });
                        }
                      },
                    )
            ),
          ),
        );
      },
    );
  }
}