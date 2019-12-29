import db_common
import ./common


type OdbcAdapter*[T] = object of AbstractAdapter[T]
type OdbcAdapterRef*[T] = ref OdbcAdapter[T]

proc get_database_version*[T](self:ptr OdbcAdapterRef[T]):int = discard