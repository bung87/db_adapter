import db_common
import ./common
import os
# https://github.com/rails/rails/blob/f33d52c95217212cbacc8d5e44b5a8e3cdc6f5b3/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb

type SqliteAdapter*[T] = object of AbstractAdapter[T]
type SqliteAdapterRef*[T] = ref SqliteAdapter[T]

proc get_database_version*[T](self:ptr SqliteAdapterRef[T]):int =
    self.conn.getValue(sql"PRAGMA schema_version;").parseInt

proc database_exists*[T](self:ptr SqliteAdapterRef[T]):bool =
    if self.config[].host == ":memory:":
        return true
    else:
        return fileExists(self.config[].host)