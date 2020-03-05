
import regex,strformat
import ../../abstract/quoting
import ../../common

type Scope* = object
    schema: string
    name: string
    typ: string

type Change* = object
    `frm`*:string
    to*:string

proc extractSchemaQualifiedName(str: string): (string, string) =
    let r = str.findAndCaptureAll(re"[^`.\s]+|`[^`]*`")
    if r.len > 1:
        result = (r[0],r[1])
    else:
        result = ("", r[0])


proc quotedScope*(name = "", typ = ""): Scope =
    let (schema, name) = extractSchemaQualifiedName(name)

    result.schema = if schema.len > 0: quote(schema) else: "database()"
    if name.len > 0:
        result.name = quote(name)
    if typ.len > 0:
        result.typ = quote(typ)


proc extractNewDefaultValue*(change:Change) :string =
    change.to
    
proc extractNewDefaultValue*(change:string) :string =
    change

proc extractNewCommentValue*(change:Change):string = extractNewDefaultValue(change)
proc extractNewCommentValue*(change:string):string = extractNewDefaultValue(change)

proc rowFormatDynamicByDefault*[T](self: ptr MysqlAdapterRef[T]):bool =
    if self.mariadb:
        self.databaseVersion >= "10.2.2"
    else:
        self.databaseVersion >= "5.7.9"

when isMainModule:
    echo extractSchemaQualifiedName("`aaa`.`bb`")
