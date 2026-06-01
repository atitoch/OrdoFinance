import '../../shared/widgets/placeholder_screen.dart';

class TransactionDetailScreen extends PlaceholderScreen {
  const TransactionDetailScreen({required String transactionId, super.key})
    : super(title: 'Transaction Detail', subtitle: transactionId);
}
