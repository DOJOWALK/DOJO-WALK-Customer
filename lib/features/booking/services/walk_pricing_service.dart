class WalkPricingService {
  WalkPricingService._();

  // No customer-facing rates are approved in POL-011 yet.
  // Keep all durations unpriced until an approved price book is configured.
  static int? priceForDuration(int durationMinutes) {
    if (durationMinutes < 20 || durationMinutes > 60) {
      return null;
    }

    return null;
  }

  static int? dailyEstimate(List<int> durations) {
    if (durations.isEmpty) return 0;

    final prices = durations.map(priceForDuration).toList();

    if (prices.any((price) => price == null)) {
      return null;
    }

    return prices.fold<int>(
      0,
      (total, price) => total + price!,
    );
  }
}
