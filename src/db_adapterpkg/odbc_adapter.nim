import db_common
import ./common

proc getDatabaseVersion*[T](self:ptr OdbcAdapterRef[T]):int = discard