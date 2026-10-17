import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Represents a file to be uploaded via multipart/form-data.
class MultipartFileItem {
  /// The form field name for this file.
  final String field;

  /// The raw file bytes.
  final Uint8List bytes;

  /// The filename to send to the server.
  final String filename;

  /// The MIME type of the file (e.g. 'image/png', 'application/pdf').
  final String? contentType;

  const MultipartFileItem({
    required this.field,
    required this.bytes,
    required this.filename,
    this.contentType,
  });

  /// Creates a [MultipartFileItem] from raw byte data.
  factory MultipartFileItem.fromBytes(
    String field,
    Uint8List bytes, {
    required String filename,
    String? contentType,
  }) {
    return MultipartFileItem(
      field: field,
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
  }

  /// Creates a [MultipartFileItem] from a UTF-8 string.
  factory MultipartFileItem.fromString(
    String field,
    String content, {
    required String filename,
    String? contentType = 'text/plain',
  }) {
    return MultipartFileItem(
      field: field,
      bytes: Uint8List.fromList(utf8.encode(content)),
      filename: filename,
      contentType: contentType,
    );
  }

  /// Converts this item into an [http.MultipartFile].
  http.MultipartFile toHttpMultipartFile() {
    MediaType? mediaType;
    if (contentType != null) {
      try {
        mediaType = MediaType.parse(contentType!);
      } catch (_) {}
    }

    return http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: filename,
      contentType: mediaType,
    );
  }
}

/// Represents the payload for a multipart/form-data HTTP request.
class MultipartPayload {
  /// Regular key-value form fields.
  final Map<String, String> fields;

  /// Files to be uploaded.
  final List<MultipartFileItem> files;

  const MultipartPayload({
    this.fields = const {},
    this.files = const [],
  });

  /// Creates a copy of this payload with additional fields or files.
  MultipartPayload copyWith({
    Map<String, String>? fields,
    List<MultipartFileItem>? files,
  }) {
    return MultipartPayload(
      fields: fields ?? this.fields,
      files: files ?? this.files,
    );
  }
}
