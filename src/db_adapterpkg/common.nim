{.experimental: "dotOperators".}

type 
    DriverKind* {.pure.} = enum
      sqlite,
      mysql,
      postgres,
      odbc
  
type
  AbstractAdapterRef*[T] = ref AbstractAdapter[T]
  AbstractAdapter*[T] = object of RootObj
    conn*: T
type DbConnection*[T] = object
        connection*: T
        adapter*:ptr AbstractAdapterRef[T]
