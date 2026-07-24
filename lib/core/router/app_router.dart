import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/reset_password_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/signup_buyer_screen.dart';
import '../../screens/auth/signup_vendor_screen.dart';
import '../../screens/home/category_listing_screen.dart';
import '../../screens/home/favorites_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/product_details_screen.dart';
import '../../screens/messages/chat_detail_screen.dart';
import '../../screens/messages/messages_screen.dart';
import '../../screens/post_ad/gate_screen.dart';
import '../../screens/post_ad/post_ad_flow_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/vendor/kyc_verification_screen.dart';
import '../../screens/vendor/subscription_screen.dart';
import '../../screens/vendor/vendor_dashboard_screen.dart';
import '../app_messenger.dart';

GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: AppMessenger.navigatorKey,
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final unauthScreens = {
        '/',
        '/role-select',
        '/login',
        '/signup/buyer',
        '/signup/vendor',
        '/forgot-password',
        '/reset-password'
      };

      // Use exact set lookup
      final onUnauthScreen = unauthScreens.contains(state.matchedLocation);

      // 1. Keep spinning while AuthProvider resolves session token
      if (auth.status == AuthStatus.unknown) return null;

      // 2. Unauthenticated user sitting on splash ('/') -> move to /role-select
      if (!auth.isLoggedIn && state.matchedLocation == '/') {
        return '/role-select';
      }

      // 3. Logged out user attempting to visit a protected route -> bounce to role-select
      if (!auth.isLoggedIn && !onUnauthScreen) {
        return '/role-select';
      }

      // 4. Authenticated user sitting on auth/splash screens -> redirect to home
      if (auth.isLoggedIn && onUnauthScreen) {
        return '/home'; // Everyone goes to /home upon sign-in
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: '/role-select',
          builder: (context, state) => const RoleSelectionScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: '/signup/buyer',
          builder: (context, state) => const SignupBuyerScreen()),
      GoRoute(
          path: '/signup/vendor',
          builder: (context, state) => const SignupVendorScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
            email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/category/:id',
        builder: (context, state) => CategoryListingScreen(
          categoryId: state.pathParameters['id']!,
          categoryName: state.uri.queryParameters['name'],
        ),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailsScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
          path: '/profile', builder: (context, state) => const ProfileScreen()),
      GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen()),
      GoRoute(
          path: '/buyer/kyc',
          builder: (context, state) => const KycVerificationScreen()),
      GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(
          path: '/messages',
          builder: (context, state) => const MessagesScreen()),
      GoRoute(
        path: '/messages/new',
        builder: (context, state) => ChatDetailScreen(
          sellerId: state.uri.queryParameters['sellerId'],
          listingId: state.uri.queryParameters['productId'],
          otherPartyName: state.uri.queryParameters['sellerName'],
        ),
      ),
      GoRoute(
        path: '/messages/:id',
        builder: (context, state) => ChatDetailScreen(
          chatId: state.pathParameters['id'],
          sellerId: state.uri.queryParameters['otherPartyId'],
          otherPartyName: state.uri.queryParameters['otherPartyName'],
          otherPartyAvatarUrl:
              (state.uri.queryParameters['otherPartyAvatar']?.isEmpty ?? true)
                  ? null
                  : state.uri.queryParameters['otherPartyAvatar'],
        ),
      ),

      // Vendor-only
      GoRoute(
          path: '/vendor/dashboard',
          builder: (context, state) => const VendorDashboardScreen()),
      GoRoute(
          path: '/vendor/kyc',
          builder: (context, state) => const KycVerificationScreen()),
      GoRoute(
          path: '/vendor/subscription',
          builder: (context, state) => const SubscriptionScreen()),

      // Post Ad
      GoRoute(
          path: '/post-ad',
          builder: (context, state) => const PostAdGateScreen()),
      GoRoute(
          path: '/post-ad/flow',
          builder: (context, state) => const PostAdFlowScreen()),
    ],
  );
}
