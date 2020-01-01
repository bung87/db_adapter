
import nre
import ../../abstract/quoting

type Scope = object
    schema: string
    name: string
    typ: string



proc extract_schema_qualified_name(str: string): (string, string) =
    let r = str.findAll(re"[^`.\s]+|`[^`]*`")
    result = (r[0], r[1])


proc quoted_scope(name = "", typ = ""): Scope =
    let (schema, name) = extract_schema_qualified_name(name)

    result.schema = if schema.len > 0: quote(schema) else: "database()"
    if name.len > 0:
        result.name = quote(name)
    if typ.len > 0:
        result.typ = quote(typ)


when isMainModule:
    echo "`aaa`.`bb`".findAll(re"[^`.\s]+|`[^`]*`")
    echo extract_schema_qualified_name("`aaa`.`bb`")
