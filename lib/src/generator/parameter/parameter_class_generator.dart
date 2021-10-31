import 'package:fantom/src/generator/components/component/generated_components.dart';
import 'package:fantom/src/generator/components/components_registrey.dart';
import 'package:fantom/src/generator/schema/schema_class_generator.dart';
import 'package:fantom/src/generator/utils/content_manifest_generator.dart';
import 'package:fantom/src/mediator/mediator/schema/schema_mediator.dart';
import 'package:fantom/src/mediator/model/schema/schema_model.dart';
import 'package:fantom/src/reader/model/model.dart';
import 'package:recase/recase.dart';
import 'package:sealed_writer/sealed_writer.dart';

class ParameterClassGenerator {
  const ParameterClassGenerator({
    required this.schemaGenerator,
    required this.schemaMediator,
    required this.contentManifestGenerator,
  });

  final SchemaClassGenerator schemaGenerator;
  final SchemaMediator schemaMediator;
  final ContentManifestCreator contentManifestGenerator;

  GeneratedParameterComponent generate(
    final OpenApi openApi,
    final Parameter parameter,
    final String nameSeed,
  ) {
    // user+id+query+parameter = UserIdQueryParameter
    final typeName =
        '$nameSeed/${parameter.name}/${parameter.location}/parameter';

    if (parameter.schema != null && parameter.content != null) {
      throw StateError('Parameter can not have both schema and content');
    } else if (parameter.content != null) {
      // UserIdQueryJson
      final subTypeName = '$nameSeed/${parameter.name}/${parameter.location}';

      // UserIdQueryBody
      final schemaTypeName =
          '$nameSeed/${parameter.name}/${parameter.location}/body';

      final contentManifest = contentManifestGenerator.generateContentType(
        typeName: typeName.pascalCase,
        subTypeName: subTypeName.pascalCase,
        generatedSchemaTypeName: schemaTypeName.pascalCase,
        content: parameter.content!,
      );

      final forward = SourceWriter(
        contentManifest.manifest,
        referToManifest: false,
      );

      final sealedClassContent = forward.write();
      final buffer = StringBuffer();

      buffer.writeln(sealedClassContent);

      for (final component in contentManifest.generatedComponents) {
        buffer.writeln(component.fileContent);
      }

      final fileContent = buffer.toString();
      final fileName = '${ReCase(typeName).snakeCase}.dart';

      return GeneratedParameterComponent.content(
        fileName: fileName,
        fileContent: fileContent,
        contentManifest: contentManifest,
        source: parameter,
      );
    } else {
      final className = typeName.pascalCase;

      final schema = parameter.schema!;
      final DataElement element = _findSchemaElement(
        openApi,
        schema,
        name: className,
      );

      if (element is ObjectDataElement) {
        final generatedSchema = schemaGenerator.generate(element);
        return GeneratedParameterComponent.schema(
          source: parameter,
          schemaComponent: generatedSchema,
          fileContent: generatedSchema.fileContent,
          fileName: generatedSchema.fileName,
        );
      } else {
        return GeneratedParameterComponent.schema(
          source: parameter,
          schemaComponent: UnGeneratableSchemaComponent(dataElement: element),
          fileContent: '',
          fileName: '',
        );
      }
    }
  }

  DataElement _findSchemaElement(
    OpenApi openApi,
    Referenceable<Schema> schema, {
    String? name,
  }) {
    if (schema.isReference) {
      final generatedComponent = getGeneratedComponentByRef(
        schema.reference.ref,
      );

      if (generatedComponent is GeneratedSchemaComponent) {
        return generatedComponent.dataElement;
      } else if (generatedComponent == null) {
        return schemaMediator.convert(
          openApi: openApi,
          schema: schema,
          name: name,
        );
      } else {
        throw StateError('Unexpected generated component type');
      }
    }

    return schemaMediator.convert(
      openApi: openApi,
      schema: schema,
      name: name,
    );
  }
}
