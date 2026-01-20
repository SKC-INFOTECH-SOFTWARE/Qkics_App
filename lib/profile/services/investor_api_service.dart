import 'package:dio/dio.dart';
import 'package:q_kics/profile/models/investor/investor_profile.dart';

class InvestorApiService {
  final Dio dio;
  InvestorApiService(this.dio);

  Future<List<InvestorProfile>> getAllInvestors() async {
    final res = await dio.get('/api/v1/investors/');
    return (res.data as List).map((e) => InvestorProfile.fromJson(e)).toList();
  }
}
