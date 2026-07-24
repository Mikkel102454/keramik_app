import 'package:ceramic_app/objects/ceramic_dto.dart';
import 'package:ceramic_app/objects/ceramic_firing_dto.dart';
import 'package:ceramic_app/objects/ceramic_stage_history_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expanded ceramic response parses dimensions outcome and timestamps', () {
    final ceramic = CeramicDto.fromJson({
      'id': 1,
      'stageId': 6,
      'title': 'Vase',
      'clayTypeId': 2,
      'rating': 5,
      'weight': 1.2,
      'note': '',
      'glazes': [
        {
          'id': 3,
          'glazeId': 4,
          'ceramicId': 1,
          'note': 'rim',
          'layerOrder': 2,
          'coatCount': 3,
        },
      ],
      'tags': [],
      'images': [],
      'heightCm': 14.5,
      'widthCm': null,
      'depthCm': 8,
      'diameterCm': 9.25,
      'outcomeNote': 'Soft satin finish',
      'createdAt': '2026-07-20T10:00:00Z',
      'updatedAt': '2026-07-22T12:00:00Z',
    });

    expect(ceramic.heightCm, 14.5);
    expect(ceramic.widthCm, isNull);
    expect(ceramic.outcomeNote, 'Soft satin finish');
    expect(ceramic.glazes.single.layerOrder, 2);
    expect(ceramic.glazes.single.coatCount, 3);
    expect(ceramic.updatedAt, DateTime.utc(2026, 7, 22, 12));
  });

  test('firing and stage history responses preserve journal events', () {
    final firing = CeramicFiringDto.fromJson({
      'id': 7,
      'ceramicId': 1,
      'status': 'COMPLETED',
      'type': 'GLAZE',
      'firingDate': '2026-07-21',
      'targetCone': '6',
      'targetTemperatureC': 1220,
      'observedCone': '6',
      'peakTemperatureC': 1218,
      'kiln': 'Studio kiln',
      'program': 'Cone fire medium',
      'note': '',
      'createdAt': '2026-07-20T10:00:00Z',
      'updatedAt': '2026-07-21T10:00:00Z',
    });
    final history = CeramicStageHistoryDto.fromJson({
      'id': 2,
      'fromStageId': 5,
      'fromStageTitle': 'Glazed',
      'toStageId': 6,
      'toStageTitle': 'Finished',
      'changedAt': '2026-07-22T10:00:00Z',
      'baseline': false,
    });

    expect(firing.type, 'GLAZE');
    expect(firing.toRequestJson()['firingDate'], '2026-07-21');
    expect(history.fromStageTitle, 'Glazed');
    expect(history.toStageTitle, 'Finished');
  });
}
