
type 
    DriverKind* {.pure.} = enum
      sqlite,
      mysql,
      postgres,
      odbc
  
  
type DbConnection*[T] = object
        connection*:T
