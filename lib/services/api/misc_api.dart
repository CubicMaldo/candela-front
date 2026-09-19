import '../../models.dart';
import '../auth_service.dart';
import 'api_client.dart';

class MiscApi {

  static Future<RankingResponse> getGlobalRanking() async {
    final j = await ApiClient.get('/api/rankings/global');
    return RankingResponse.fromJson(ApiClient.asMap(j));
  }

  static Future<RankingResponse> getFriendsRanking() async {
    final j = await ApiClient.get('/api/rankings/friends');
    return RankingResponse.fromJson(ApiClient.asMap(j));
  }

  
  static Future<Report> createReport(CreateReportRequest request) async {
    final j = await ApiClient.post('/api/reports', request.toJson());
    return Report.fromJson(ApiClient.asMap(j));
  }

  

}

