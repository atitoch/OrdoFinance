class MonthSummary {
  const MonthSummary({
    required this.period,
    required this.totalIncome,
    required this.totalExpense,
    required this.netBalance,
    required this.byCategory,
    required this.byAccount,
    required this.txCount,
    required this.savingsRate,
  });

  final String period;
  final int totalIncome;
  final int totalExpense;
  final int netBalance;
  final List<CategoryStat> byCategory;
  final List<AccountStat> byAccount;
  final int txCount;
  final double savingsRate;

  factory MonthSummary.fromJson(Map<String, dynamic> json) {
    return MonthSummary(
      period: json['period'] as String,
      totalIncome: json['totalIncome'] as int,
      totalExpense: json['totalExpense'] as int,
      netBalance: json['netBalance'] as int,
      byCategory: (json['byCategory'] as List<dynamic>)
          .map((item) => CategoryStat.fromJson(item as Map<String, dynamic>))
          .toList(),
      byAccount: (json['byAccount'] as List<dynamic>)
          .map((item) => AccountStat.fromJson(item as Map<String, dynamic>))
          .toList(),
      txCount: json['txCount'] as int,
      savingsRate: (json['savingsRate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period': period,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'netBalance': netBalance,
      'byCategory': byCategory.map((item) => item.toJson()).toList(),
      'byAccount': byAccount.map((item) => item.toJson()).toList(),
      'txCount': txCount,
      'savingsRate': savingsRate,
    };
  }
}

class CategoryStat {
  const CategoryStat({
    required this.categoryId,
    required this.categoryName,
    required this.color,
    required this.total,
    required this.percentage,
  });

  final String categoryId;
  final String categoryName;
  final String color;
  final int total;
  final double percentage;

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      categoryId: json['categoryId'] as String,
      categoryName: json['categoryName'] as String,
      color: json['color'] as String,
      total: json['total'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'color': color,
      'total': total,
      'percentage': percentage,
    };
  }
}

class AccountStat {
  const AccountStat({
    required this.accountId,
    required this.accountName,
    required this.balance,
  });

  final String accountId;
  final String accountName;
  final int balance;

  factory AccountStat.fromJson(Map<String, dynamic> json) {
    return AccountStat(
      accountId: json['accountId'] as String,
      accountName: json['accountName'] as String,
      balance: json['balance'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'balance': balance,
    };
  }
}
