import '../../models.dart';
import '../auth_service.dart';
import 'api_client.dart';

class UsersApi {

  static Future<User> getMyProfile() async {
    try {
      final j = await ApiClient.get('/api/me');
      return User.fromJson(ApiClient.asMap(j));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // The account behind the stored token no longer exists — log out.
        await TokenStorage.clear();
        ApiClient.onSessionExpired?.call();
        throw const SessionExpiredException();
      }
      rethrow;
    }
  }

  static Future<PublicProfile> getPublicProfile(String username) async {
    final j = await ApiClient.get('/api/users/$username');
    return PublicProfile.fromJson(ApiClient.asMap(j));
  }

  /// Username prefix search for the friends screen.
  static Future<List<UserSearchResult>> searchUsers(String query) async {
    final j = await ApiClient.get('/api/users?q=${Uri.encodeQueryComponent(query)}');
    final m = ApiClient.asMap(j);
    return (m['users'] as List? ?? const [])
        .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updatePrivacy(PrivacyMode mode) =>
      ApiClient.patch('/api/me/privacy', {'privacy_mode': mode.raw});

  static Future<bool> updateRankingOptIn(bool optIn) async {
    final j = await ApiClient.patch('/api/me/ranking', {'ranking_opt_in': optIn});
    return ApiClient.asMap(j)['ranking_opt_in'] == true;
  }

  
  static Future<void> sendFriendRequest(String userId) =>
      ApiClient.post('/api/users/$userId/friend-request');

  static Future<void> acceptFriendRequest(String userId) =>
      ApiClient.post('/api/friend-requests/$userId/accept');

  static Future<void> rejectFriendRequest(String userId) =>
      ApiClient.post('/api/friend-requests/$userId/reject');

  static Future<void> cancelFriendRequest(String userId) =>
      ApiClient.delete('/api/friend-requests/$userId');

  static Future<void> removeFriend(String userId) =>
      ApiClient.delete('/api/users/$userId/friend');

  static Future<List<FeedUser>> getFriends() async {
    final j = await ApiClient.get('/api/me/friends');
    final m = ApiClient.asMap(j);
    return (m['friends'] as List? ?? const [])
        .map((e) => FeedUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<FriendRequest>> getIncomingRequests() async {
    final j = await ApiClient.get('/api/friend-requests/incoming');
    final m = ApiClient.asMap(j);
    return (m['requests'] as List? ?? const [])
        .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<FriendRequest>> getOutgoingRequests() async {
    final j = await ApiClient.get('/api/friend-requests/outgoing');
    final m = ApiClient.asMap(j);
    return (m['requests'] as List? ?? const [])
        .map((e) => FriendRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  
  static Future<void> blockUser(String userId) =>
      ApiClient.post('/api/users/$userId/block');

  static Future<void> unblockUser(String userId) =>
      ApiClient.delete('/api/users/$userId/block');

  
}

