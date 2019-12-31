{.experimental: "dotOperators".}
import ./utils
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

