import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_app/core/utils/validators.dart';

void main() {
  group('Validators Tests', () {
    group('required', () {
      test('returns null for valid input', () {
        expect(Validators.required('test'), isNull);
        expect(Validators.required('  valid  '), isNull);
      });
      
      test('returns error for invalid input', () {
        expect(Validators.required(null), isNotNull);
        expect(Validators.required(''), isNotNull);
        expect(Validators.required('  '), isNotNull);
      });
      
      test('uses custom field name', () {
        final result = Validators.required(null, fieldName: 'Username');
        expect(result, contains('Username'));
      });
    });
    
    group('email', () {
      test('returns null for valid emails', () {
        expect(Validators.email('test@example.com'), isNull);
        expect(Validators.email('user.name@domain.co.uk'), isNull);
        expect(Validators.email('123@test.org'), isNull);
      });
      
      test('returns error for invalid emails', () {
        expect(Validators.email('invalid'), isNotNull);
        expect(Validators.email('@domain.com'), isNotNull);
        expect(Validators.email('test@'), isNotNull);
        expect(Validators.email(''), isNotNull);
        expect(Validators.email(null), isNotNull);
      });
    });
    
    group('minLength', () {
      test('returns null for valid length', () {
        expect(Validators.minLength('12345', 5), isNull);
        expect(Validators.minLength('123456', 5), isNull);
      });
      
      test('returns error for invalid length', () {
        expect(Validators.minLength('1234', 5), isNotNull);
        expect(Validators.minLength('', 1), isNotNull);
        expect(Validators.minLength(null, 1), isNotNull);
      });
    });
    
    group('maxLength', () {
      test('returns null for valid length', () {
        expect(Validators.maxLength('12345', 5), isNull);
        expect(Validators.maxLength('1234', 5), isNull);
        expect(Validators.maxLength(null, 5), isNull);
      });
      
      test('returns error for invalid length', () {
        expect(Validators.maxLength('123456', 5), isNotNull);
      });
    });
    
    group('url', () {
      test('returns null for valid URLs', () {
        expect(Validators.url('https://example.com'), isNull);
        expect(Validators.url('http://test.org'), isNull);
        expect(Validators.url('https://www.example.com/path?query=1'), isNull);
        expect(Validators.url(null), isNull); // Optional field
        expect(Validators.url(''), isNull); // Optional field
      });
      
      test('returns error for invalid URLs', () {
        expect(Validators.url('not-a-url'), isNotNull);
        expect(Validators.url('ftp://example.com'), isNotNull);
        expect(Validators.url('example'), isNotNull);
      });
    });
    
    group('combine', () {
      test('returns first error encountered', () {
        final validators = [
          (String? value) => Validators.required(value),
          (String? value) => Validators.minLength(value, 5),
        ];
        
        expect(Validators.combine(null, validators), contains('required'));
        expect(Validators.combine('12', validators), contains('5 characters'));
        expect(Validators.combine('12345', validators), isNull);
      });
    });
  });
}