import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:chashibhai/core/models/models.dart';
import 'package:chashibhai/features/account/presentation/state/app_state_provider.dart';
import 'package:chashibhai/features/account/presentation/views/edit_profile_screen.dart';
import 'package:chashibhai/features/account/presentation/views/profile_screen.dart';
import 'package:chashibhai/features/auth/presentation/providers/auth_provider.dart';

void main() {
  testWidgets('ProfileScreen renders user profile with hero header, KPIs and actions', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    authProvider.setCurrentUser(
      AppUser(
        id: '92f6839a-5d0c-40a7-bd92-a5080cd8b070',
        name: 'Rafiq Ahmed',
        role: UserRole.farmer,
        phone: '01740719205',
        rating: 4.8,
        walletBalance: 25000.0,
        isVerified: true,
        email: 'rafiq@example.com',
        avatarUrl: 'https://cdn.example.com/avatar.jpg',
        district: 'Bogura',
      ),
    );
    final appStateProvider = AppStateProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify User details rendered
    expect(find.text('Rafiq Ahmed'), findsWidgets);
    expect(find.text('Bogura'), findsWidgets);
    expect(find.text('Farmer'), findsWidgets);
    expect(find.text('01740719205'), findsWidgets);
    expect(find.text('rafiq@example.com'), findsWidgets);
    expect(find.text('Edit Profile'), findsWidgets);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('EditProfileScreen renders editable fields and district presets', (WidgetTester tester) async {
    final authProvider = AuthProvider();
    authProvider.setCurrentUser(
      AppUser(
        id: '92f6839a-5d0c-40a7-bd92-a5080cd8b070',
        name: 'Rafiq Ahmed',
        role: UserRole.farmer,
        phone: '01740719205',
        district: 'Bogura',
        avatarUrl: 'https://cdn.example.com/avatar.jpg',
      ),
    );
    final appStateProvider = AppStateProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AppStateProvider>.value(value: appStateProvider),
        ],
        child: const MaterialApp(
          home: EditProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Form Fields
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('Avatar URL'), findsOneWidget);
    expect(find.text('Phone Number (Account ID)'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });
}
