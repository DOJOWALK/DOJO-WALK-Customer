class WalkPricingService {
  WalkPricingService._();

  // Current draft rate: 30-minute walk = ₹149.
  // Add other approved rates here when finalized.
  static int? priceForDuration(int durationMinutes) {
    if (durationMinutes == 30) return 149;
    return null;
  }

  static int? dailyEstimate(List<int> durations) {
    final prices = durations
        .map(priceForDuration)
        .toList();

    if (prices.any((price) => price == null)) {
      return null;
    }

    return prices.fold<int>(
      0,
      (total, price) => total + price!,
    );
  }
}
