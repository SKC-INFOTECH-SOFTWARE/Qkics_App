// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:q_kics/main.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/providers/booking_provider.dart';
import 'package:q_kics/providers/navigation_provider.dart';
import 'package:q_kics/providers/profile_provider.dart';
import 'package:q_kics/providers/expert_profile_provider.dart';
import 'package:q_kics/providers/entrepreneur_profile_provider.dart';
import 'package:q_kics/providers/authorized_profiles_provider.dart';
import 'package:q_kics/profile/services/profile_api_service.dart';
import 'package:q_kics/profile/services/expert_api_service.dart';
import 'package:q_kics/profile/services/entrepreneur_api_service.dart';
import 'package:q_kics/profile/services/investor_api_service.dart';
import 'package:q_kics/subscriptions/providers/subscription_provider.dart';
import 'package:q_kics/subscriptions/services/subscription_service.dart';
import 'package:dio/dio.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    // Inject required providers
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ApiProvider()),
          ChangeNotifierProvider(create: (_) => BookingProvider()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(
            create: (_) =>
                ProfileProvider(ProfileApiService(Dio()), ApiProvider()),
          ),
          ChangeNotifierProvider(
            create: (_) => ExpertProfileProvider(ExpertApiService(Dio())),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                EntrepreneurProfileProvider(EntrepreneurApiService(Dio())),
          ),
          ChangeNotifierProvider(
            create: (_) => AuthorizedProfilesProvider(
              expertApi: ExpertApiService(Dio()),
              entrepreneurApi: EntrepreneurApiService(Dio()),
              investorApi: InvestorApiService(Dio()),
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => SubscriptionProvider(SubscriptionService(Dio())),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Let all frames, animations, and async tasks finish
    await tester.pumpAndSettle();

    // Verify that MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
