import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/call_provider.dart';
import 'providers/favorites_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/vendor_status_provider.dart';

void main() {
  runApp(const SbraiHubApp());
}

class SbraiHubApp extends StatelessWidget {
  const SbraiHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => VendorStatusProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        // Created once for the app's whole lifetime — it registers with
        // RealtimeService immediately so an incoming call can be caught
        // no matter which screen the user is currently on.
        ChangeNotifierProvider(create: (_) => CallProvider()),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          final router = buildRouter(auth);
          return MaterialApp.router(
            title: 'Sbrai Hub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
