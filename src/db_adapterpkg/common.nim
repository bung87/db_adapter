{.experimental: "dotOperators".}
import ./utils
import db_common
export utils
type 
    DriverKind* {.pure.} = enum
      sqlite,
      mysql,
      postgres,
      odbc

type DbConfig* = object
  host*, username*, password*, database*:string
    
type DbConfigRef* = ref DbConfig
    
type
  AbstractAdapterRef*[T] = ref AbstractAdapter[T]
  AbstractAdapter*[T] = object of RootObj
    conn*: T
    config*:ptr DbConfigRef
    database_version*:Version

type PostgresAdapter*[T] = object of AbstractAdapter[T]
type PostgresAdapterRef*[T] = ref PostgresAdapter[T]


type MysqlAdapter*[T] = object of AbstractAdapter[T]
  full_version_string: string

type MysqlAdapterRef*[T] = ref MysqlAdapter[T]

type OdbcAdapter*[T] = object of AbstractAdapter[T]
type OdbcAdapterRef*[T] = ref OdbcAdapter[T]

type SqliteAdapter*[T] = object of AbstractAdapter[T]

type SqliteAdapterRef*[T] = ref SqliteAdapter[T]

proc dbQuote*(s: string): string =
  ## Escapes the `'` (single quote) char to `''`.
  ## Because single quote is used for defining `VARCHAR` in SQL.
  runnableExamples:
    doAssert dbQuote("'") == "''''"
    doAssert dbQuote("A Foobar's pen.") == "'A Foobar''s pen.'"

  result = "'"
  for c in items(s):
    if c == '\'': add(result, "''")
    else: add(result, c)
  add(result, '\'')

proc dbFormat*(formatstr: SqlQuery, args: varargs[string]): string =
  result = ""
  var a = 0
  for c in items(string(formatstr)):
    if c == '?':
      add(result, dbQuote(args[a]))
      inc(a)
    else:
      add(result, c)

