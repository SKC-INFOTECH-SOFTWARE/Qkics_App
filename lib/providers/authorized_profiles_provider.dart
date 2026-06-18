import 'package:flutter/material.dart';
import 'package:q_kics/profile/models/expert/expert_profile_model.dart';
import 'package:q_kics/profile/models/entrepreneur/entrepreneur_profile_model.dart';
import 'package:q_kics/profile/models/investor/investor_profile.dart';
import 'package:q_kics/profile/services/expert_api_service.dart';
import 'package:q_kics/profile/services/entrepreneur_api_service.dart';
import 'package:q_kics/profile/services/investor_api_service.dart';

class AuthorizedProfilesProvider extends ChangeNotifier {
  final ExpertApiService expertApi;
  final EntrepreneurApiService entrepreneurApi;
  final InvestorApiService investorApi;

  AuthorizedProfilesProvider({
    required this.expertApi,
    required this.entrepreneurApi,
    required this.investorApi,
  });

  List<ExpertProfile> experts = [];
  List<EntrepreneurProfile> entrepreneurs = [];
  List<InvestorProfile> investors = [];

  bool isLoading = false;
  String? error;

  Future<void> fetchAll({String? search}) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        expertApi.getAllExperts(search: search),
        entrepreneurApi.getAllEntrepreneurs(search: search),
        investorApi.getAllInvestors(search: search),
      ]);

      experts = results[0] as List<ExpertProfile>;
      entrepreneurs = results[1] as List<EntrepreneurProfile>;
      investors = results[2] as List<InvestorProfile>;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExperts({String? search}) async {
    isLoading = true;
    notifyListeners();
    try {
      experts = await expertApi.getAllExperts(search: search);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchEntrepreneurs({String? search}) async {
    isLoading = true;
    notifyListeners();
    try {
      entrepreneurs = await entrepreneurApi.getAllEntrepreneurs(search: search);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvestors({String? search}) async {
    isLoading = true;
    notifyListeners();
    try {
      investors = await investorApi.getAllInvestors(search: search);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
