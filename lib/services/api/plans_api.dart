import '../../models.dart';
import '../auth_service.dart';
import 'api_client.dart';

class PlansApi {

  /// Proposes a plan. [targetUserId] is required only for
  /// [PlanVisibility.invite]; open (public/friends) plans leave it null.
  static Future<Plan> createPlan({
    String? targetUserId,
    required String placeId,
    required String message,
    required int deadlineHours,
    PlanVisibility visibility = PlanVisibility.invite,
  }) async {
    final j = await ApiClient.post('/api/plans', {
      'target_user_id': ?targetUserId,
      'place_id': placeId,
      'message': message,
      'deadline_hours': deadlineHours,
      'visibility': visibility.raw,
    });
    return Plan.fromJson(ApiClient.asMap(j));
  }

  /// Joins an open plan as a participant.
  static Future<Plan> joinPlan(String planId) async {
    final j = await ApiClient.post('/api/plans/$planId/join');
    return Plan.fromJson(ApiClient.asMap(j));
  }

  /// Open plans near (lat, lon) the user can join — for the map.
  static Future<List<OpenPlan>> discoverOpenPlans({
    required double lat,
    required double lon,
  }) async {
    final j = await ApiClient.get('/api/plans/discover?lat=$lat&lon=$lon');
    final m = ApiClient.asMap(j);
    return (m['plans'] as List? ?? const [])
        .map((e) => OpenPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Plan>> getIncomingPlans() async {
    final j = await ApiClient.get('/api/plans/incoming');
    final m = ApiClient.asMap(j);
    return (m['plans'] as List? ?? const [])
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Plan>> getOutgoingPlans() async {
    final j = await ApiClient.get('/api/plans/outgoing');
    final m = ApiClient.asMap(j);
    return (m['plans'] as List? ?? const [])
        .map((e) => Plan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Plan> getPlanById(String planId) async {
    final j = await ApiClient.get('/api/plans/$planId');
    return Plan.fromJson(ApiClient.asMap(j));
  }

  static Future<Plan> acceptPlan(String planId) async {
    final j = await ApiClient.post('/api/plans/$planId/accept');
    return Plan.fromJson(ApiClient.asMap(j));
  }

  // Both respond 204 No Content — nothing to parse.
  static Future<void> declinePlan(String planId) =>
      ApiClient.post('/api/plans/$planId/decline');

  static Future<void> cancelPlan(String planId) =>
      ApiClient.delete('/api/plans/$planId');

  
}

