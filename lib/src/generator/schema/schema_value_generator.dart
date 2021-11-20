import 'package:fantom/src/generator/utils/string_utils.dart';
import 'package:fantom/src/mediator/model/schema/schema_model.dart';

class SchemaValueGenerator {
  const SchemaValueGenerator();

  String generate(
    final DataElement element, {
    required final Object? value,
  }) {
    if (element.hasEnum) {
      // todo: uie, enum item names
      // ex. Status.value1
      final values = element.enumeration!.values;
      for (var index = 0; index <= values.length; index++) {
        if (_deepEquals(value, values[index])) {
          return element.enumName + '.' + 'value$index';
        }
      }
      throw AssertionError('enum item not found');
    } else {
      if (value == null) {
        if (!element.isNullable) {
          throw AssertionError('bad types');
        }
        return 'null';
      } else {
        return element.match(
          boolean: (boolean) {
            // ex. "true"
            if (value is! bool) {
              throw AssertionError('bad types');
            }
            return _primitive(value);
          },
          object: (object) {
            if (value is! Map<String, Object?>) {
              throw AssertionError('bad types');
            }
            final format = object.format;
            if (format == ObjectDataElementFormat.map) {
              // ex. <String, int>{'a': 12}
              final additionalProperties = object.additionalProperties!;
              final sub = additionalProperties.type1;
              final joined = value.entries
                  .map((e) {
                    return _string(e.key) +
                        ': ' +
                        // recursive call:
                        generate(additionalProperties, value: e.value);
                  })
                  .toList()
                  .joinArgsFull();
              return '<String, $sub>{$joined}';
            } else {
              // ex. User(name: 'john')
              // note: we have handled `null` value so no need for `User?`
              final additionalProperties = object.additionalProperties;
              final name = object.name;

              final propertiesMap = Map.fromEntries(
                object.properties.map((e) => MapEntry(e.name, e)).toList(),
              );

              final fixedValues = Map.of(value)
                // remove all fixed properties
                ..removeWhere((key, _) => !propertiesMap.containsKey(key));
              final additionalValues = Map.of(value)
                // include all fixed properties
                ..removeWhere((key, _) => propertiesMap.containsKey(key));

              if (additionalValues.isNotEmpty && additionalProperties == null) {
                throw AssertionError(
                  'non-additive object with additional fields',
                );
              }

              if (format == ObjectDataElementFormat.mixed) {
                throw UnimplementedError(
                  'mixed objects is not supported',
                );
              }

              return [
                '$name(',
                for (final key in fixedValues.keys)
                  [
                    '$key : ',
                    if (propertiesMap[key]!.isConstructorOptional) 'Optional(',
                    generate(
                      propertiesMap[key]!.item,
                      value: fixedValues[key],
                    ),
                    if (propertiesMap[key]!.isConstructorOptional) ')',
                    ',',
                  ].joinParts(),
                // if (object.format == ObjectDataElementFormat.mixed)
                //   [
                //     'additionalProperties: ',
                //     generate(additionalProperties!, value: additionalValues),
                //     ','
                //   ].joinParts(),
                ')',
              ].joinParts();
            }
          },
          array: (array) {
            // ex. <int>[1,2,3]
            // ex. <int?>{1,2,3}
            // ex. <List<int>>[[1,2],[3,4]]
            if (value is! List<Object?>) {
              throw AssertionError('bad types');
            }
            final sub = array.items.type1;
            // both set and list are stored as list in json and yaml:
            final joined = value
                // recursive call:
                .map((e) => generate(array.items, value: e))
                .toList()
                .joinArgsFull();
            return '<$sub>' + (array.isUniqueItems ? '{$joined}' : '[$joined]');
          },
          integer: (integer) {
            // ex. "1"
            if (value is! int) {
              throw AssertionError('bad types');
            }
            return _primitive(value);
          },
          number: (number) {
            // ex. "1.5"
            // or "1" if type is num
            if (number.isFloat) {
              if (value is! double) {
                throw AssertionError('bad types');
              }
            } else {
              if (value is! num) {
                throw AssertionError('bad types');
              }
            }
            return _primitive(value);
          },
          string: (string) {
            // ex. "'hello'"
            final format = string.format;
            if (format == StringDataElementFormat.binary) {
              // todo: uie
              throw UnimplementedError(
                'binary string is not supported',
              );
            }

            if (value is! String) {
              throw AssertionError('bad types');
            }
            if (format == StringDataElementFormat.plain ||
                format == StringDataElementFormat.byte) {
              return _string(value);
            } else if (format == StringDataElementFormat.date ||
                format == StringDataElementFormat.dateTime) {
              return 'DateTime.parse(${_string(value)})';
            } else {
              throw AssertionError();
            }
          },
          untyped: (untyped) {
            return _untyped(value);
          },
        );
      }
    }
  }

  /// primitive to string
  String _primitive(Object value) => '$value';

  /// string to string
  String _string(Object value) => "'$value'";

  /// untyped element
  String _untyped(Object? value) {
    if (value == null) {
      return 'null';
    } else if (value is String) {
      return _string(value);
    } else if (value is num || value is bool) {
      return _primitive(value);
    } else if (value is List<Object?>) {
      // in untyped we don't have sets
      final joined = value
          .map(
            (e) =>
                // recursive call:
                _untyped(e),
          )
          .joinArgsFull();
      return '<Object?>[$joined]';
    } else if (value is Map<String, Object?>) {
      final joined = value.entries
          .map(
            (e) => [
              "'${e.key}': ",
              // recursive call:
              _untyped(e.value),
            ].joinParts(),
          )
          .joinArgsFull();
      return '<String, Object?>{$joined}';
    } else {
      throw AssertionError();
    }
  }

  // todo: uie, sets ?
  bool _deepEquals(final Object? o1, final Object? o2) {
    if (o1 == null && o2 == null) {
      return true;
    } else if (o1 is int && o2 is int) {
      return o1 == o2;
    } else if (o1 is double && o2 is double) {
      return o1 == o2;
    } else if (o1 is bool && o2 is bool) {
      return o1 == o2;
    } else if (o1 is String && o2 is String) {
      return o1 == o2;
    } else if (o1 is List<Object?> && o2 is List<Object?>) {
      if (o1.length == o2.length) {
        for (var index = 0; index < o1.length; index++) {
          if (!_deepEquals(o1[index], o2[index])) {
            return false;
          }
        }
        return true;
      } else {
        return false;
      }
    } else if (o1 is Set<Object?> && o2 is Set<Object?>) {
      if (o1.length == o2.length) {
        final acc = Set.of(o2);
        for (final item1 in o1) {
          bool isFound = false;
          Object? found;
          for (final item2 in acc) {
            if (_deepEquals(item1, item2)) {
              isFound = true;
              found = item2;
              break;
            }
          }
          if (isFound) {
            acc.remove(found);
          } else {
            return false;
          }
        }
        return true;
      } else {
        return false;
      }
    } else if (o1 is Map<String, Object?> && o2 is Map<String, Object?>) {
      if (o1.length == o2.length) {
        for (var key in o1.keys) {
          if (!o2.containsKey(key)) {
            return false;
          } else {
            if (!_deepEquals(o1[key], o2[key])) {
              return false;
            }
          }
        }
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }
}
