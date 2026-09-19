import '../../models.dart';
import '../auth_service.dart';
import 'api_client.dart';

class FeedApi {

  /// One page of the city feed, plus the cursor for the next one.
  ///
  /// The cursor is opaque and must come from [FeedPage.nextCursor] — the feed
  /// is ordered by priority layer before time, so a timestamp taken from the
  /// last event does not describe a position in it and paging on one returns
  /// events the reader has already seen.
  static Future<FeedPage> getFeed({String? cursor, int limit = 20}) async {
    final query = StringBuffer('?limit=$limit');
    if (cursor != null) {
      query.write('&cursor=${Uri.encodeQueryComponent(cursor)}');
    }
    final j = await ApiClient.get('/api/feed$query');
    final m = ApiClient.asMap(j);
    final rawEvents = (m['events'] as List? ?? const []);
    return FeedPage(
      events: rawEvents
          .where((e) => e is Map && (e['type'] == null || e['type'] == 'checkin'))
          .map((e) => CheckInEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: m['next_cursor'] as String?,
    );
  }

  static Future<List<CheckInEvent>> getEventFeed(
    String placeId, {
    String? cursor,
    int limit = 20,
  }) async {
    final query = StringBuffer('?limit=$limit');
    if (cursor != null) {
      query.write('&before=${Uri.encodeQueryComponent(cursor)}');
    }
    final j = await ApiClient.get('/api/places/$placeId/feed$query');
    final m = ApiClient.asMap(j);
    return (m['events'] as List? ?? const [])
        .map((e) => CheckInEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  

  }
}
