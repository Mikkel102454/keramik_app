import 'package:ceramic_app/app/app_settings_controller.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:ceramic_app/objects/account_settings_dto.dart';
import 'package:ceramic_app/objects/shared_ceramic_dto.dart';
import 'package:ceramic_app/repositories/chat_repository.dart';
import 'package:ceramic_app/utils/measurement.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef LoadSharedCeramic =
    Future<SharedCeramicDetailDto> Function(
      String conversationId,
      String messageId,
    );

class SharedCeramicDetailPage extends StatefulWidget {
  const SharedCeramicDetailPage({
    required this.conversationId,
    required this.messageId,
    this.loadDetail,
    super.key,
  });

  final String conversationId;
  final String messageId;
  final LoadSharedCeramic? loadDetail;

  @override
  State<SharedCeramicDetailPage> createState() => _SharedCeramicDetailPageState();
}

class _SharedCeramicDetailPageState extends State<SharedCeramicDetailPage> {
  late Future<SharedCeramicDetailDto> _detail = _load();

  Future<SharedCeramicDetailDto> _load() {
    return (widget.loadDetail ?? ChatRepository.getSharedCeramic)(
      widget.conversationId,
      widget.messageId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.sharedCeramic)),
      body: FutureBuilder<SharedCeramicDetailDto>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.sharedCeramicLoadFailed),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(() => _detail = _load()),
                    child: Text(context.l10n.retry),
                  ),
                ],
              ),
            );
          }
          final detail = snapshot.requireData;
          if (!detail.available) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hide_image_outlined, size: 52),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.ceramicUnavailable,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return _SharedCeramicContent(detail: detail);
        },
      ),
    );
  }
}

class _SharedCeramicContent extends StatelessWidget {
  const _SharedCeramicContent({required this.detail});

  final SharedCeramicDetailDto detail;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMd(locale).add_Hm();
    final units = AppSettingsController.instance.measurementSystem;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        if (detail.images.isNotEmpty)
          SizedBox(
            height: 280,
            child: PageView(
              children: detail.images
                  .map(
                    (image) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: ColoredBox(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Image.network(image.uri, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
        else
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.handyman_outlined, size: 54),
          ),
        const SizedBox(height: 18),
        Text(
          detail.title ?? '',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text(localizedStageName(context.l10n, detail.stage ?? '')),
            ),
            if (detail.clayTitle?.isNotEmpty == true)
              Chip(label: Text(detail.clayTitle!)),
            Chip(
              avatar: const Icon(Icons.star_rounded, size: 18),
              label: Text('${detail.rating ?? 0}'),
            ),
          ],
        ),
        _Section(
          title: context.l10n.measurements,
          children: [
            _Value(context.l10n.weight, _weight(detail.weight, units)),
            _Value(context.l10n.height, _centimeters(detail.heightCm)),
            _Value(context.l10n.width, _centimeters(detail.widthCm)),
            _Value(context.l10n.depth, _centimeters(detail.depthCm)),
            _Value(context.l10n.diameter, _centimeters(detail.diameterCm)),
          ],
        ),
        _Section(
          title: context.l10n.glazeApplications,
          children: detail.glazes.isEmpty
              ? [Text(context.l10n.noGlazeApplications)]
              : detail.glazes
                    .map(
                      (glaze) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(glaze.title),
                        subtitle: Text(
                          [
                            context.l10n.coatCount(glaze.coatCount),
                            if (glaze.note.isNotEmpty) glaze.note,
                          ].join('\n'),
                        ),
                      ),
                    )
                    .toList(),
        ),
        _Section(
          title: context.l10n.firings,
          children: detail.firings.isEmpty
              ? [Text(context.l10n.noFiringRecords)]
              : detail.firings
                    .map(
                      (firing) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${firing.type} · ${firing.status}'),
                        subtitle: Text(
                          [
                            if (firing.firingDate != null)
                              DateFormat.yMMMd(locale).format(firing.firingDate!),
                            if (firing.targetTemperatureC != null)
                              '${firing.targetTemperatureC} °C',
                            if (firing.note.isNotEmpty) firing.note,
                          ].join('\n'),
                        ),
                      ),
                    )
                    .toList(),
        ),
        _Section(
          title: context.l10n.tags,
          children: detail.tags.isEmpty
              ? [Text(context.l10n.noTags)]
              : [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: detail.tags.map((tag) => Chip(label: Text(tag))).toList(),
                  ),
                ],
        ),
        _Section(
          title: context.l10n.projectNotes,
          children: [Text(_text(detail.note))],
        ),
        _Section(
          title: context.l10n.outcome,
          children: [Text(_text(detail.outcomeNote))],
        ),
        _CollapsibleSection(
          title: context.l10n.history,
          children: detail.stageHistory
              .map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.timeline),
                  title: Text(
                    localizedStageName(context.l10n, event.toStageTitle),
                  ),
                  subtitle: Text(date.format(event.changedAt.toLocal())),
                ),
              )
              .toList(),
        ),
        _Section(
          title: context.l10n.timestamps,
          children: [
            if (detail.createdAt != null)
              _Value(context.l10n.created, date.format(detail.createdAt!)),
            if (detail.updatedAt != null)
              _Value(context.l10n.updated, date.format(detail.updatedAt!)),
          ],
        ),
      ],
    );
  }

  String _weight(double? value, MeasurementSystem units) {
    if (value == null) return '—';
    if (units == MeasurementSystem.metric) return '$value kg';
    final displayValue = Measurement.weightFromKilograms(value, units);
    return '${Measurement.format(displayValue)} ${units.weightSymbol}';
  }

  String _centimeters(double? value) => value == null ? '—' : '$value cm';
  String _text(String? value) => value?.trim().isNotEmpty == true ? value! : '—';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        children: children,
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
