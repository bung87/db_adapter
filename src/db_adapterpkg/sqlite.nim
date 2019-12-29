import db_common
import ./common


type SqliteAdapter*[T] = object of AbstractAdapter[T]
type SqliteAdapterRef*[T] = ref SqliteAdapter[T]

proc get_database_version*[T](self:ptr SqliteAdapterRef[T]):int =
    self.conn.getValue(sql"PRAGMA schema_version;").parseInt
