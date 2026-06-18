import 'package:dio/dio.dart';
import 'package:q_kics/profile/models/investor/investor_profile.dart';

class InvestorApiService {
  final Dio dio;
  InvestorApiService(this.dio);

  Future<List<InvestorProfile>> getAllInvestors({String? search}) async {
    final res = await dio.get(
      '/api/v1/investors/',
      queryParameters: (search != null && search.isNotEmpty) ? {'search': search} : null,
    );

    final data = res.data as Map<String, dynamic>;
    final List<dynamic> results = data['results'];

    return results
        .map((e) => InvestorProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
