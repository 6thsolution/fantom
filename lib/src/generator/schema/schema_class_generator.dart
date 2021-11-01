import 'package:fantom/src/generator/components/component/generated_components.dart';
import 'package:fantom/src/generator/schema/schema_class_from_json_generator.dart';
import 'package:fantom/src/generator/schema/schema_class_to_json_generator.dart';
import 'package:fantom/src/generator/schema/schema_default_value_generator.dart';
import 'package:fantom/src/generator/utils/string_utils.dart';
import 'package:fantom/src/mediator/model/schema/schema_model.dart';
import 'package:recase/recase.dart';

class SchemaClassGenerator {
  const SchemaClassGenerator();

  GeneratedSchemaComponent generate(final ObjectDataElement object) {
    final name = object.name;
    if (name == null) {
      throw UnimplementedError('anonymous objects are not supported');
    }

    return GeneratedSchemaComponent(
      dataElement: object,
      fileContent: _generate(object),
      fileName: _fileName(object),
    );
  }

  String _fileName(ObjectDataElement object) {
    final name = object.name!;
    return '${ReCase(name).snakeCase}.dart';
  }

  String _generate(final ObjectDataElement object) {
    final name = object.name!;
    final format = object.format;

    if (format != ObjectDataElementFormat.object) {
      throw UnimplementedError(
        '"mixed" and "map" objects are not supported : name is $name',
      );
    }
    for (final property in object.properties) {
      if (property.item.type == null) {
        throw UnimplementedError('anonymous inner objects are not supported');
      }
    }

    return object.properties.isEmpty
        // empty class:
        ? 'class $name {}'
        // non-empty class:
        : [
            'class $name {',
            // ...
            [
              for (final property in object.properties)
                [
                  'final ',
                  if (property.isFieldOptional) 'Optional<',
                  property.item.type!,
                  if (property.isFieldOptional) '>?',
                  ' ',
                  property.name,
                  ';',
                ].joinParts(),
            ].joinLines(),
            // ...
            [
              '${object.name} ({',
              // .../...
              [
                for (final property in object.properties)
                  [
                    if (property.isRequired && property.item.isNotNullable)
                      'required ',
                    if (property.isNotRequired || property.item.hasDefaultValue)
                      'Optional<',
                    property.item.type!,
                    if (property.isNotRequired || property.item.hasDefaultValue)
                      '>?',
                    ' ',
                    property.name,
                    ',',
                  ].joinParts(),
              ].joinLines(),
              '}) : ',
              // .../...
              [
                for (final property in object.properties)
                  [
                    property.name,
                    ' = ',
                    property.name,
                    if (property.item.hasDefaultValue)
                      [
                        ' != null ? ',
                        property.name,
                        '.value : ',
                        SchemaDefaultValueGenerator().generate(property.item)!,
                      ].joinParts(),
                    ',',
                  ].joinParts(),
              ].joinLines().replaceFromLastOrNot(',', ';'),
            ].joinLines(),
            SchemaClassToJsonGenerator().generate(object),
            SchemaClassFromJsonGenerator().generate(object),
            '}',
          ].joinLines();
  }
}
