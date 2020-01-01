import db_common
import ./common



proc get_database_version*[T](self:ptr PostgresAdapterRef[T]):int = discard