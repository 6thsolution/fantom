part of 'model.dart';

class Responses {
  /// described as [default] in documentation.
  /// but [default], is a keyword in Dart.
  final Referenceable<Response>? defaultValue;

  /// other key-value pairs
  final Map<String, Referenceable<Response>>? map;

  const Responses({
    required this.defaultValue,
    required this.map,
  });

  factory Responses.fromMap(Map<String, dynamic> map) {
    // Mapping responses object
    final responses = map.map<String, Referenceable<Response>>(
      (key, value) => MapEntry(
        key,
        !value.containsKey('\$ref')
            ? Referenceable.value(Response.fromMap(value))
            : Referenceable.reference(Reference.fromMap(value)),
      ),
    );

    final otherValue = responses.remove('default');

    return Responses(
      map: responses,
      defaultValue: otherValue,
    );
  }
}
