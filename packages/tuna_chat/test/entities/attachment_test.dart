import 'package:tuna_chat/tuna_chat.dart';
import 'package:test/test.dart';

void main() {
  const attachment = Attachment(
    fileUrl: 'https://example.com/file.pdf',
    fileName: 'file.pdf',
    fileSize: 1024,
    mimeType: 'application/pdf',
  );

  const imageAttachment = Attachment(
    fileUrl: 'https://example.com/photo.jpg',
    fileName: 'photo.jpg',
    fileSize: 204800,
    mimeType: 'image/jpeg',
  );

  // ── Equality ───────────────────────────────────────────────────────────────
  group('Attachment — equality', () {
    test('same fields → equal', () {
      const a = Attachment(
        fileUrl: 'https://example.com/file.pdf',
        fileName: 'file.pdf',
        fileSize: 1024,
        mimeType: 'application/pdf',
      );
      expect(a, equals(attachment));
    });

    test('different fileUrl → not equal', () {
      const other = Attachment(
        fileUrl: 'https://other.com/file.pdf',
        fileName: 'file.pdf',
        fileSize: 1024,
        mimeType: 'application/pdf',
      );
      expect(other, isNot(equals(attachment)));
    });
  });

  // ── isImage ────────────────────────────────────────────────────────────────
  group('Attachment.isImage', () {
    test('image/jpeg → true', () => expect(imageAttachment.isImage, isTrue));
    test('image/png → true', () {
      const a = Attachment(
        fileUrl: 'u',
        fileName: 'f.png',
        fileSize: 0,
        mimeType: 'image/png',
      );
      expect(a.isImage, isTrue);
    });
    test('application/pdf → false', () => expect(attachment.isImage, isFalse));
    test('text/plain → false', () {
      const a = Attachment(
        fileUrl: 'u',
        fileName: 'f.txt',
        fileSize: 0,
        mimeType: 'text/plain',
      );
      expect(a.isImage, isFalse);
    });
  });

  // ── fromJson / toJson ──────────────────────────────────────────────────────
  group('Attachment — serialization', () {
    test('fromJson parses all fields', () {
      final json = {
        'file_url': 'https://example.com/file.pdf',
        'file_name': 'file.pdf',
        'file_size': 1024,
        'mime_type': 'application/pdf',
      };
      expect(Attachment.fromJson(json), equals(attachment));
    });

    test('fromJson accepts num file_size (double)', () {
      final json = {
        'file_url': 'https://example.com/file.pdf',
        'file_name': 'file.pdf',
        'file_size': 1024.0,
        'mime_type': 'application/pdf',
      };
      expect(Attachment.fromJson(json).fileSize, equals(1024));
    });

    test('toJson produces correct keys', () {
      final json = attachment.toJson();
      expect(json['file_url'], 'https://example.com/file.pdf');
      expect(json['file_name'], 'file.pdf');
      expect(json['file_size'], 1024);
      expect(json['mime_type'], 'application/pdf');
    });

    test('round-trip: fromJson(toJson()) == original', () {
      expect(Attachment.fromJson(attachment.toJson()), equals(attachment));
    });
  });
}
