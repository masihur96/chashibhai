import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chashibhai/features/account/presentation/state/app_state_provider.dart';
import 'package:chashibhai/features/account/presentation/state/review_provider.dart';
import 'package:chashibhai/features/auth/presentation/state/auth_provider.dart';
import 'package:chashibhai/features/buyer/presentation/state/demand_provider.dart';
import 'package:chashibhai/features/buyer/presentation/state/product_provider.dart';
import 'package:chashibhai/features/group/presentation/state/group_provider.dart';
import 'package:chashibhai/features/wallet/presentation/state/order_provider.dart';
import 'package:chashibhai/main.dart';

void main() {
  testWidgets('App root smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => GroupProvider()),
          ChangeNotifierProvider(create: (_) => DemandProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Pump past splash screen's 2-second delay
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify app builds
    expect(find.byType(MyApp), findsOneWidget);
  });
}
