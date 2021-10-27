part of 'model.dart';

class Operation extends Equatable {
  final String? operationId;

  final List<Referenceable<Parameter>>? parameters;

  final Referenceable<RequestBody>? requestBody;

  // [responses] is required in version 3.0.3
  final Responses responses;

  final bool? deprecated;

  /// we only check if security	is not empty
  final bool hasSecurity;

  const Operation({
    required this.parameters,
    required this.requestBody,
    required this.responses,
    required this.deprecated,
    required this.hasSecurity,
    required this.operationId,
  });

  factory Operation.fromMap(Map<String, dynamic> map) => Operation(
        parameters: (map['parameters'] as List<dynamic>?)?.mapToList(
          (e) => Referenceable.fromMap(
            e,
            builder: (m) => Parameter.fromMap(m),
          ),
        ),
        requestBody: map['requestBody'] == null
            ? null
            : Referenceable.fromMap(
                map['requestBody'],
                builder: (m) => RequestBody.fromMap(m),
              ),
        responses: Responses.fromMap(map['responses']),
        deprecated: map['deprecated'],
        // security property is a list of objects
        hasSecurity:
            map['security'] != null && (map['security'] as List).isNotEmpty,
        operationId: map['operationId'],
      );

  @override
  List<Object?> get props => [
        parameters,
        requestBody,
        responses,
        deprecated,
        hasSecurity,
        operationId,
      ];
}
