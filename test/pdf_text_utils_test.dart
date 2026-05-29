import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_offline_ai_doc_chat/shared/services/pdf_text_utils.dart';

void main() {
  group('isSubstantialEmbeddedText', () {
    test('accepts long embedded text', () {
      const text =
          'This is a digital PDF paragraph with enough English content to pass the threshold check.';
      expect(isSubstantialEmbeddedText(text), isTrue);
    });

    test('accepts Bengali embedded text', () {
      const text =
          'বাংলা টেক্সট এখানে আছে এবং এটি যথেষ্ট দৈর্ঘ্যের হওয়া উচিত যাতে এটি গ্রহণযোগ্য হয়।';
      expect(isSubstantialEmbeddedText(text), isTrue);
    });

    test('rejects empty or very short text', () {
      expect(isSubstantialEmbeddedText(''), isFalse);
      expect(isSubstantialEmbeddedText('Hi'), isFalse);
    });

    test('rejects mostly replacement characters', () {
      expect(isSubstantialEmbeddedText('?' * 100), isFalse);
    });
  });
}
