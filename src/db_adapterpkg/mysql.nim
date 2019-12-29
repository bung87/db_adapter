import db_common
import ./common


type MysqlAdapter*[T] = object of AbstractAdapter[T]
type MysqlAdapterRef*[T] = ref MysqlAdapter[T]

proc get_database_version*[T](self:ptr MysqlAdapterRef[T]):int = discard