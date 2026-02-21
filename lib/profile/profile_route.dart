import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/providers/profile_provider.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';
import 'package:q_kics/providers/entrepreneur_profile_provider.dart';
import 'package:q_kics/providers/investor_profile_provider.dart';

import 'package:q_kics/profile/services/profile_api_service.dart';
import 'package:q_kics/profile/services/expert_api_service.dart';
import 'package:q_kics/profile/services/entrepreneur_api_service.dart';

import 'package:q_kics/profile/ui/profile_screen.dart';

// ============================================================
// PROFILE ROUTE (PRIVATE PROFILE ENTRY POINT)
// ============================================================

class ProfileRoute extends StatelessWidget {
  final ValueChanged<bool>? onBarsVisibilityChanged;

  const ProfileRoute({super.key, this.onBarsVisibilityChanged});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiProvider>();

    return MultiProvider(
      providers: [
        // ================= CORE PROFILE =================
        ChangeNotifierProvider(
          create: (_) =>
              ProfileProvider(ProfileApiService(api.dio), api)..loadProfile(),
        ),

        // ================= EXPERT PROFILE =================
        ChangeNotifierProvider(
          create: (_) => ExpertProfileProvider(ExpertApiService(api.dio)),
        ),

        // ================= ENTREPRENEUR PROFILE =================
        ChangeNotifierProvider(
          create: (_) =>
              EntrepreneurProfileProvider(EntrepreneurApiService(api.dio)),
        ),

        // ================= INVESTOR PROFILE =================
        ChangeNotifierProvider(create: (_) => InvestorProfileProvider(api.dio)),
      ],
      child: ProfileScreen(onBarsVisibilityChanged: onBarsVisibilityChanged),
    );
  }
}
