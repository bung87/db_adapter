import db_common
import ./common


type PostgresAdapter*[T] = object of AbstractAdapter[T]
type PostgresAdapterRef*[T] = ref PostgresAdapter[T]

proc get_database_version*[T](self:ptr PostgresAdapterRef[T]):int = discard