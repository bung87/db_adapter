import db_common
import ./common

proc get_database_version*[T](self:DbConnection[T]):int =
    self.getValue(sql"PRAGMA schema_version;").parseInt
