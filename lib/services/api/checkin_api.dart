import '../../models.dart';
import '../auth_service.dart';
import 'api_client.dart';

class CheckInApi {

  static Future<CheckInInitiation> initiateCheckIn({
    required String placeId,
    required double lat,
    required double lon,
  }) async {
    final j = await ApiClient.post('/api/places/$placeId/checkin/initiate', {
      'lat': lat,
      'lon': lon,
    });
    return CheckInInitiation.fromJson(ApiClient.asMap(j));
  }

  static Future<ConfirmCheckInResult> confirmCheckIn({
    required String placeId,
    required String checkinNonce,
    required String photoKey,
    DateTime? capturedAt,
    bool photoIsPermanent = false,
  }) async {
    final payload = <String, dynamic>{
      'checkin_nonce': checkinNonce,
      'photo_key': photoKey,
      'photo_is_permanent': photoIsPermanent,
    };
    if (capturedAt != null) {
      payload['exif_timestamp'] = capturedAt.toUtc().toIso8601String();
    }
    final j = await ApiClient.post('/api/places/$placeId/checkin/confirm', payload);
    return ConfirmCheckInResult.fromJson(ApiClient.asMap(j));
  }

  static Future<bool> setPhotoPermanent(
    String checkinId,
    bool permanent,
  ) async {
    final j = await ApiClient.patch('/api/checkins/$checkinId/permanent', {
      'permanent': permanent,
    });
    return ApiClient.asMap(j)['photo_is_permanent'] == true;
  }

  static Future<List<MyCheckIn>> getMyCheckIns({
    int limit = 20,
    String? cursor,
  }) async {
    var path = '/api/me/check-ins?limit=$limit';
    if (cursor != null) path += '&before=$cursor';
    final j = await ApiClient.get(path);
    final m = ApiClient.asMap(j);
    return (m['check_ins'] as List? ?? const [])
        .map((e) => MyCheckIn.fromJson(e as Map<String, dynamic>))
        .toList();
  

  }
}
