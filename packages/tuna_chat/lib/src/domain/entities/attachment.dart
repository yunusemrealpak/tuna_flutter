import 'package:equatable/equatable.dart';

/// A file attachment associated with a [Message].
///
/// Created by uploading a file via `POST /channels/:channelId/upload` and
/// then including the returned metadata when sending a message.
class Attachment extends Equatable {
  const Attachment({
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
  });

  /// Public URL of the uploaded file (MinIO / storage backend).
  final String fileUrl;

  /// Original filename as uploaded by the sender.
  final String fileName;

  /// File size in bytes.
  final int fileSize;

  /// MIME type as detected by the storage backend (e.g. `image/jpeg`).
  final String mimeType;

  bool get isImage => mimeType.startsWith('image/');

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        fileUrl: json['file_url'] as String,
        fileName: json['file_name'] as String,
        fileSize: (json['file_size'] as num).toInt(),
        mimeType: json['mime_type'] as String,
      );

  Map<String, dynamic> toJson() => {
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
        'mime_type': mimeType,
      };

  @override
  List<Object?> get props => [fileUrl, fileName, fileSize, mimeType];
}
