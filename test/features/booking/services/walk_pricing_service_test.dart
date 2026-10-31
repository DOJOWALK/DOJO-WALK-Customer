import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_walk_customer/features/booking/services/walk_pricing_service.dart';

void main() {
  group('WalkPricingService', () {
    test('does not expose candidate prices before Founder approval', () {
      for (final duration in [20, 25, 30, 40, 45, 60]) {
        expect(
          WalkPricingService.priceForDuration(duration),
          isNull,
          reason: '$duration-minute pricing is not approved in POL-011',
        );
      }
    });

    test('does not estimate a total while rates are unapproved', () {
      expect(WalkPricingService.dailyEstimate([30, 30]), isNull);
    });

    test('does not estimate a mixed-duration total while rates are unapproved',
        () {
      expect(WalkPricingService.dailyEstimate([30, 45]), isNull);
    });

    test('returns null for an out-of-policy duration', () {
      expect(WalkPricingService.priceForDuration(15), isNull);
      expect(WalkPricingService.priceForDuration(61), isNull);
    });

    test('returns zero for an empty list', () {
      expect(WalkPricingService.dailyEstimate([]), 0);
    });
  });
}
