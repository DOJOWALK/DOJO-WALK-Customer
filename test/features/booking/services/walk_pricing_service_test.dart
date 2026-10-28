import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_walk_customer/features/booking/services/walk_pricing_service.dart';

void main() {
  group('WalkPricingService', () {
    test('returns the configured draft price for a 30-minute walk', () {
      expect(WalkPricingService.priceForDuration(30), 149);
    });

    test('does not invent prices for unapproved durations', () {
      for (final duration in [20, 25, 40, 45, 60]) {
        expect(
          WalkPricingService.priceForDuration(duration),
          isNull,
          reason: '$duration-minute pricing has not been approved',
        );
      }
    });

    test('calculates a daily estimate when every duration is priced', () {
      expect(WalkPricingService.dailyEstimate([30, 30]), 298);
    });

    test('returns null when any duration has no configured price', () {
      expect(WalkPricingService.dailyEstimate([30, 45]), isNull);
    });

    test('returns zero for an empty list', () {
      expect(WalkPricingService.dailyEstimate([]), 0);
    });
  });
}
