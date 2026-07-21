import 'package:ceramic_app/ui/pages/materials/glazes/glazes_create/glazes_create_page_controller.dart';
import 'package:ceramic_app/ui/widgets/v2/text_field_widget.dart';
import 'package:ceramic_app/ui/widgets/v2/text_widget.dart';
import 'package:flutter/material.dart';

class GlazesCreatePage extends StatefulWidget {
  const GlazesCreatePage({super.key});

  @override
  State<GlazesCreatePage> createState() => _GlazesCreatePageState();
}

class _GlazesCreatePageState extends State<GlazesCreatePage> {
  final GlazesCreatePageController _controller = GlazesCreatePageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glaze'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _createGlaze),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TextWidget(
                text: 'Information',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: 8),
              TextWidget(
                text: 'Title',
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 4),
              TextFieldWidget(
                placeholder: 'Title',
                onChanged: (value) async {
                  _controller.setTitle(value);
                  return true;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createGlaze() async {
    if (_controller.title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a title')),
      );
      return;
    }
    try {
      await _controller.create();
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }
}
