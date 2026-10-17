import 'dart:convert';
import 'package:flutter/foundation.dart';

/// A function type signature that deserializes a JSON map into a model of type [T].
typedef JsonParser<T> = T Function(Map<String, dynamic> json);

/// Base class for all data models in the flutter_mvc framework.
@immutable
abstract class MVCModel {
  const MVCModel();

  /// Converts this model instance into a JSON-compatible map.
  Map<String, dynamic> toJson();

  /// Encodes this model to a JSON string representation.
  String toJsonString() => jsonEncode(toJson());

  /// Helper utility to parse a list of JSON objects into a list of [T].
  static List<T> fromJsonList<T>(dynamic rawJson, JsonParser<T> parser) {
    if (rawJson == null) return <T>[];

    final dynamic listData;
    if (rawJson is String) {
      listData = jsonDecode(rawJson);
    } else {
      listData = rawJson;
    }

    if (listData is List) {
      return listData
          .whereType<Map<String, dynamic>>()
          .map((item) => parser(item))
          .toList();
    } else if (listData is Map<String, dynamic>) {
      // Common API response structures where items are nested under "data", "items", "results"
      const keys = ['data', 'items', 'results', 'records'];
      for (final key in keys) {
        if (listData.containsKey(key) && listData[key] is List) {
          return (listData[key] as List)
              .whereType<Map<String, dynamic>>()
              .map((item) => parser(item))
              .toList();
        }
      }
    }
    return <T>[];
  }
}
