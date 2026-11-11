class Persona {
  const Persona(
    this.id,
    this.type,
    this.name,
    this.aliases,
    this.isSelf,
    this.attributes,
  );
  factory Persona.fromJson(Map<String, dynamic> value) => Persona(
    '${value['persona_id']}',
    '${value['type']}',
    '${value['name']}',
    (value['aliases'] as List? ?? const []).cast<String>(),
    value['is_self'] == true,
    (value['attributes'] as Map? ?? const {}).cast<String, dynamic>(),
  );
  final String id;
  final String type;
  final String name;
  final List<String> aliases;
  final bool isSelf;
  final Map<String, dynamic> attributes;
}

class PersonaField {
  const PersonaField(this.name, this.type, this.required, this.inContext);
  factory PersonaField.fromJson(Map<String, dynamic> value) => PersonaField(
    '${value['name']}',
    '${value['type']}',
    value['required'] == true,
    value['in_context'] == true,
  );
  final String name;
  final String type;
  final bool required;
  final bool inContext;
}

class PersonaSchema {
  const PersonaSchema(this.type, this.version, this.fields);
  factory PersonaSchema.fromJson(Map<String, dynamic> value) =>
      PersonaSchema('${value['type']}', (value['version'] as num).toInt(), [
        for (final field in value['fields'] as List)
          PersonaField.fromJson((field as Map).cast()),
      ]);
  final String type;
  final int version;
  final List<PersonaField> fields;
}
