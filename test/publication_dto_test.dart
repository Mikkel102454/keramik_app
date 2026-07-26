import 'package:ceramic_app/objects/publication_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publication cards parse the curated Discover contract', () {
    final value = PublicationCardDto.fromJson({
      'publicationId': '1f2f8816-99c4-4c73-92b7-44b684077c20',
      'creator': {
        'userId': 'e6606496-9879-48b0-a475-755602797ebc',
        'username': 'potter',
        'avatarUrl': null,
        'avatarInitials': 'PO',
        'avatarColor': '#355070',
      },
      'primaryImage': {'id': 7, 'uri': 'https://example.invalid/image'},
      'title': 'Blue bowl',
      'clay': 'Stoneware',
      'likeCount': 4,
      'likedByMe': true,
      'ownedByMe': false,
      'publishedAt': '2026-07-25T12:00:00Z',
    });

    expect(value.title, 'Blue bowl');
    expect(value.primaryImage?.id, 7);
    expect(value.likeCount, 4);
    expect(value.creator.username, 'potter');
  });

  test('Discover page parsing preserves its opaque cursor', () {
    final page = DiscoverPageDto.fromJson({
      'items': <Object>[],
      'nextCursor': 'opaque-token',
    });
    expect(page.items, isEmpty);
    expect(page.nextCursor, 'opaque-token');
  });

  test('publication detail parses only the curated public contract', () {
    final detail = PublicationDetailDto.fromJson({
      'publicationId': '1f2f8816-99c4-4c73-92b7-44b684077c20',
      'creator': {
        'userId': 'e6606496-9879-48b0-a475-755602797ebc',
        'username': 'potter',
        'avatarUrl': null,
        'avatarInitials': 'PO',
        'avatarColor': '#355070',
      },
      'images': [
        {'id': 7, 'uri': 'https://example.invalid/image'},
      ],
      'totalImageCount': 1,
      'title': 'Blue bowl',
      'clay': 'Stoneware',
      'tags': ['blue'],
      'rating': 5,
      'heightCm': 8.5,
      'widthCm': null,
      'depthCm': null,
      'diameterCm': 12,
      'outcome': 'Even glaze',
      'publishedAt': '2026-07-25T12:00:00Z',
      'likeCount': 4,
      'likedByMe': true,
      'currentAudience': 'EVERYONE',
    });

    expect(detail.images.single.id, 7);
    expect(detail.tags, ['blue']);
    expect(detail.heightCm, 8.5);
    expect(detail.outcome, 'Even glaze');
  });
}
