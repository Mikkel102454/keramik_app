import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/ui/pages/materials/clays/clays_page.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/glazes_page.dart';
import 'package:ceramic_app/ui/pages/materials/glazes/notebook/glaze_notebook_page.dart';
import 'package:ceramic_app/ui/pages/materials/inventory/material_inventory_page.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/studio_widgets.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MaterialsPage extends StatelessWidget {
  const MaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget page) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    return StudioScaffold(
      currentPage: NavigationPage.materials,
      appBar: AppBar(title: Text(context.l10n.materials)),
      body: SafeArea(
        child: StudioContent(
          maxWidth: StudioSpacing.formWidth,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              StudioFeatureTile(
                title: context.l10n.clays,
                icon: Icons.landscape_outlined,
                onTap: () => open(const ClaysPage()),
              ),
              const Divider(height: 1),
              StudioFeatureTile(
                title: context.l10n.glazes,
                icon: Icons.opacity_outlined,
                onTap: () => open(const GlazesPage()),
              ),
              const Divider(height: 1),
              StudioFeatureTile(
                title: context.l10n.materialInventory,
                icon: Icons.inventory_2_outlined,
                onTap: () => open(const MaterialInventoryPage()),
              ),
              const SizedBox(height: 20),
              StudioSectionHeading(title: context.l10n.glazeApplications),
              StudioFeatureTile(
                title: context.l10n.glazeCombinations,
                icon: Icons.layers_outlined,
                onTap: () => open(const GlazeNotebookPage(tiles: false)),
              ),
              const Divider(height: 1),
              StudioFeatureTile(
                title: context.l10n.testTileNotebook,
                icon: Icons.science_outlined,
                onTap: () => open(const GlazeNotebookPage(tiles: true)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
