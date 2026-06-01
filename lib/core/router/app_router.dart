import 'package:go_router/go_router.dart';

import '../../features/accounts/screens/account_detail_screen.dart';
import '../../features/accounts/screens/account_list_screen.dart';
import '../../features/accounts/add_account_screen.dart';
import '../../features/categories/screens/categories_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/stats/screens/stats_screen.dart';
import '../../features/transactions/add_transaction_screen.dart';
import '../../features/transactions/screens/transaction_detail_screen.dart';
import '../../features/transactions/screens/transaction_list_screen.dart';
import '../network/app_keys.dart';
import '../../features/login_screen.dart';
import '../../features/search_placeholder_screen.dart';
import '../../shared/widgets/app_shell.dart';

abstract final class AppRouteNames {
  static const home = 'home';
  static const transactions = 'transactions';
  static const transactionDetail = 'transactionDetail';
  static const addTransaction = 'addTransaction';
  static const accounts = 'accounts';
  static const addAccount = 'addAccount';
  static const accountDetail = 'accountDetail';
  static const categories = 'categories';
  static const stats = 'stats';
  static const settings = 'settings';
}

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: AppRouteNames.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/stats',
              name: AppRouteNames.stats,
              builder: (context, state) => const StatsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transactions',
              name: AppRouteNames.transactions,
              builder: (context, state) => TransactionListScreen(
                accountId: state.uri.queryParameters['accountId'],
              ),
              routes: [
                GoRoute(
                  path: 'new',
                  name: AppRouteNames.addTransaction,
                  builder: (context, state) => const AddTransactionScreen(),
                ),
                GoRoute(
                  path: ':id',
                  name: AppRouteNames.transactionDetail,
                  builder: (context, state) => TransactionDetailScreen(
                    transactionId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: AppRouteNames.settings,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/accounts',
      name: AppRouteNames.accounts,
      builder: (context, state) => const AccountListScreen(),
      routes: [
        GoRoute(
          path: 'new',
          name: AppRouteNames.addAccount,
          builder: (context, state) => const AddAccountScreen(),
        ),
        GoRoute(
          path: ':id',
          name: AppRouteNames.accountDetail,
          builder: (context, state) =>
              AccountDetailScreen(accountId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/categories',
      name: AppRouteNames.categories,
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPlaceholderScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchPlaceholderScreen(),
    ),
  ],
);
