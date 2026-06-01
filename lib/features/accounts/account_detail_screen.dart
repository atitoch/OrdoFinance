import '../../shared/widgets/placeholder_screen.dart';

class AccountDetailScreen extends PlaceholderScreen {
  const AccountDetailScreen({required String accountId, super.key})
    : super(title: 'Account Detail', subtitle: accountId);
}
