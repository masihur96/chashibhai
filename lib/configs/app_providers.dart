import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../features/auth/presentation/state/auth_provider.dart';
import '../features/buyer/presentation/state/product_provider.dart';
import '../features/group/presentation/state/group_provider.dart';
import '../features/buyer/presentation/state/demand_provider.dart';
import '../features/wallet/presentation/state/order_provider.dart';
import '../features/account/presentation/state/app_state_provider.dart';
import '../features/account/presentation/state/review_provider.dart';

class AppProviders {
  AppProviders._();

  static List<SingleChildWidget> get providers => [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ProductProvider()),
    ChangeNotifierProvider(create: (_) => GroupProvider()),
    ChangeNotifierProvider(create: (_) => DemandProvider()),
    ChangeNotifierProvider(create: (_) => OrderProvider()),
    ChangeNotifierProvider(create: (_) => AppStateProvider()),
    ChangeNotifierProvider(create: (_) => ReviewProvider()),
  ];
}
