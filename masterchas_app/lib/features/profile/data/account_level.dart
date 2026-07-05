enum AccountTier { bronze, silver, gold, platinum }

class AccountLevelInfo {
  const AccountLevelInfo({
    required this.tier,
    required this.label,
    required this.nextTier,
    required this.pointsToNext,
    required this.progress,
  });

  final AccountTier tier;
  final String label;
  final AccountTier? nextTier;
  final int pointsToNext;
  final double progress;
}

AccountLevelInfo accountLevelFor({required int spent, required int orders}) {
  AccountTier tier;
  if (orders >= 10 || spent >= 5000) {
    tier = AccountTier.platinum;
  } else if (orders >= 5 || spent >= 2000) {
    tier = AccountTier.gold;
  } else if (orders >= 1 || spent >= 500) {
    tier = AccountTier.silver;
  } else {
    tier = AccountTier.bronze;
  }

  switch (tier) {
    case AccountTier.bronze:
      final left = (500 - spent).clamp(0, 500);
      return AccountLevelInfo(
        tier: tier,
        label: 'Bronze',
        nextTier: AccountTier.silver,
        pointsToNext: left,
        progress: (spent / 500).clamp(0.05, 0.95),
      );
    case AccountTier.silver:
      final left = (2000 - spent).clamp(0, 2000);
      return AccountLevelInfo(
        tier: tier,
        label: 'Silver',
        nextTier: AccountTier.gold,
        pointsToNext: left,
        progress: ((spent - 500) / 1500).clamp(0.05, 0.95),
      );
    case AccountTier.gold:
      final left = (5000 - spent).clamp(0, 5000);
      return AccountLevelInfo(
        tier: tier,
        label: 'Gold',
        nextTier: AccountTier.platinum,
        pointsToNext: left,
        progress: ((spent - 2000) / 3000).clamp(0.05, 0.95),
      );
    case AccountTier.platinum:
      return const AccountLevelInfo(
        tier: AccountTier.platinum,
        label: 'Platinum',
        nextTier: null,
        pointsToNext: 0,
        progress: 1,
      );
  }
}
