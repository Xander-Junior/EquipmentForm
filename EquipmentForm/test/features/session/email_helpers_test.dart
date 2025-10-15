import 'package:flutter_test/flutter_test.dart';

import 'package:equipment_form_app/features/session/view/widgets/party_session_step.dart';

void main() {
  group('Tullow email helpers', () {
    test('shouldOfferTullowDomainChip matches expected usernames', () {
      expect(shouldOfferTullowDomainChip('jane.doe@'), isTrue);
      expect(shouldOfferTullowDomainChip('jane_doe@'), isTrue);
      expect(shouldOfferTullowDomainChip('JANE.DOE@'), isTrue);
      expect(shouldOfferTullowDomainChip('janedoe@'), isFalse);
      expect(shouldOfferTullowDomainChip('jane.doe@example.com'), isFalse);
    });

    test('appendTullowDomain appends domain when eligible', () {
      expect(appendTullowDomain('jane.doe@'), 'jane.doe@tullowoil.com');
      expect(appendTullowDomain(' jane_doe@ '), 'jane_doe@tullowoil.com');
      expect(appendTullowDomain('janedoe@'), 'janedoe@');
      expect(appendTullowDomain('jane.doe@example.com'), 'jane.doe@example.com');
    });

    test('basicEmailValidationError validates syntax', () {
      expect(basicEmailValidationError(''), isNull);
      expect(basicEmailValidationError('jane.doe@'), isNull);
      expect(basicEmailValidationError('jane.doe@tullowoil.com'), isNull);
      expect(basicEmailValidationError('not-an-email'), 'Enter a valid email address');
      expect(basicEmailValidationError('jane@company'), 'Enter a valid email address');
    });
  });
}
