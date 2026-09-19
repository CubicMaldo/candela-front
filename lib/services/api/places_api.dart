import '../../models.dart';
import '../auth_service.dart';
import 'api_client.dart';

class PlacesApi {

  static Future<List<Place>> getNearbyPlaces({
    required double lat,
    required double lon,
  }) async {
    final j = await ApiClient.get('/api/places/nearby?lat=$lat&lon=$lon');
    final list = j is List ? j : (ApiClient.asMap(j)['data'] as List? ?? const []);
    return list.map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Place> getPlaceDetail(String placeId) async {
    final j = await ApiClient.get('/api/places/$placeId');
    return Place.fromJson(ApiClient.asMap(j));
  }

  
  static Future<(bool, int)> followPlace(String placeId) async {
    final j = await ApiClient.post('/api/places/$placeId/follow');
    final m = ApiClient.asMap(j);
    return (m['following'] == true, ApiClient.intOf(m['follower_count']));
  }

  static Future<(bool, int)> unfollowPlace(String placeId) async {
    final j = await ApiClient.delete('/api/places/$placeId/follow');
    final m = ApiClient.asMap(j);
    return (m['following'] == true, ApiClient.intOf(m['follower_count']));
  

  }
}
