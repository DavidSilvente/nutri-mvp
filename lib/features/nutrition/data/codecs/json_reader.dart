/// Raised when decoded JSON does not have the expected shape.
///
/// Carries a dotted path to the offending field so a malformed plan points at
/// what is actually wrong instead of producing a bare type-cast error.
class JsonReadException implements Exception {
  JsonReadException(this.message);

  final String message;

  @override
  String toString() => 'JsonReadException: $message';
}

/// A small typed accessor over a decoded JSON map.
///
/// Exists so codecs read fields once, with a path in every error, rather than
/// scattering `as Map<String, dynamic>` casts that fail without saying where.
class JsonReader {
  JsonReader(this._map, this.path);

  /// Wraps [value] as an object reader, failing if it is not a JSON object.
  factory JsonReader.object(Object? value, String path) {
    if (value is! Map) {
      throw JsonReadException('$path: expected an object, got ${_type(value)}');
    }
    return JsonReader(value, path);
  }

  final Map<Object?, Object?> _map;

  /// Dotted path of this object within the document, for error messages.
  final String path;

  bool has(String key) => _map.containsKey(key);

  Object? _require(String key) {
    if (!_map.containsKey(key)) {
      throw JsonReadException('$path.$key: missing required field');
    }
    return _map[key];
  }

  String string(String key) {
    final value = _require(key);
    if (value is! String) {
      throw JsonReadException(
        '$path.$key: expected a string, got ${_type(value)}',
      );
    }
    return value;
  }

  String? stringOrNull(String key) {
    final value = _map[key];
    if (value == null) return null;
    if (value is! String) {
      throw JsonReadException(
        '$path.$key: expected a string or null, got ${_type(value)}',
      );
    }
    return value;
  }

  num number(String key) {
    final value = _require(key);
    if (value is! num) {
      throw JsonReadException(
        '$path.$key: expected a number, got ${_type(value)}',
      );
    }
    return value;
  }

  num? numberOrNull(String key) {
    final value = _map[key];
    if (value == null) return null;
    if (value is! num) {
      throw JsonReadException(
        '$path.$key: expected a number or null, got ${_type(value)}',
      );
    }
    return value;
  }

  int integer(String key) {
    final value = number(key);
    if (value is! int) {
      throw JsonReadException('$path.$key: expected an integer, got $value');
    }
    return value;
  }

  /// A nested object under [key].
  JsonReader child(String key) =>
      JsonReader.object(_require(key), '$path.$key');

  /// A nested object under [key], or null when absent or explicitly null.
  JsonReader? childOrNull(String key) {
    final value = _map[key];
    if (value == null) return null;
    return JsonReader.object(value, '$path.$key');
  }

  /// A list of nested objects under [key].
  List<JsonReader> objectList(String key) {
    final value = _require(key);
    if (value is! List) {
      throw JsonReadException(
        '$path.$key: expected a list, got ${_type(value)}',
      );
    }
    return [
      for (var i = 0; i < value.length; i++)
        JsonReader.object(value[i], '$path.$key[$i]'),
    ];
  }

  /// A list of integers under [key]. Missing key yields an empty list.
  List<int> integerList(String key) {
    final value = _map[key];
    if (value == null) return const [];
    if (value is! List) {
      throw JsonReadException(
        '$path.$key: expected a list, got ${_type(value)}',
      );
    }
    return [
      for (var i = 0; i < value.length; i++)
        if (value[i] case final int element)
          element
        else
          throw JsonReadException(
            '$path.$key[$i]: expected an integer, got ${_type(value[i])}',
          ),
    ];
  }

  /// A list of strings under [key]. Missing key yields an empty list.
  List<String> stringList(String key) {
    final value = _map[key];
    if (value == null) return const [];
    if (value is! List) {
      throw JsonReadException(
        '$path.$key: expected a list, got ${_type(value)}',
      );
    }
    return [
      for (var i = 0; i < value.length; i++)
        if (value[i] case final String element)
          element
        else
          throw JsonReadException(
            '$path.$key[$i]: expected a string, got ${_type(value[i])}',
          ),
    ];
  }

  static String _type(Object? value) =>
      value == null ? 'null' : value.runtimeType.toString();
}
