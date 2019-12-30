import db_common
import ./common
import os

# https://github.com/rails/rails/blob/f33d52c95217212cbacc8d5e44b5a8e3cdc6f5b3/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb
type SqliteAdapter*[T] = object of AbstractAdapter[T]
    
type SqliteAdapterRef*[T] = ref SqliteAdapter[T]

proc get_database_version*[T](self:ptr SqliteAdapterRef[T]):Version =
    self.conn.getValue(sql"SELECT sqlite_version(*);")

proc database_exists*[T](self:ptr SqliteAdapterRef[T]):bool =
    if self.config[].host == ":memory:":
        return true
    else:
        return fileExists(self.config[].host)
# database_version in schema_cache https://github.com/rails/rails/blob/96289cfb9b6aeb8f1a917f892148fd47f2f2049a/activerecord/lib/active_record/connection_adapters/schema_cache.rb#L33
proc supports_ddl_transactions*[T](self:ptr SqliteAdapterRef[T]):bool = true
proc supports_savepoints*[T](self:ptr SqliteAdapterRef[T]):bool = true
proc supports_expression_index*[T](self:ptr SqliteAdapterRef[T]):bool = self.database_version >= "3.9.0"
proc requires_reloading*[T](self:ptr SqliteAdapterRef[T]):bool = true
proc supports_foreign_keys*[T](self:ptr SqliteAdapterRef[T]):bool = true
proc supports_views*[T](self:ptr SqliteAdapterRef[T]):bool = true
proc supports_datetime_with_precision*[T](self:ptr SqliteAdapterRef[T]):bool = true
proc supports_json*[T](self:ptr SqliteAdapterRef[T]):bool = true
proc supports_common_table_expressions*[T](self:ptr SqliteAdapterRef[T]):bool = self.database_version >= "3.8.3"
proc supports_insert_on_conflict*[T](self:ptr SqliteAdapterRef[T]):bool = self.database_version >= "3.24.0"
proc supports_insert_on_duplicate_skip*[T](self:ptr SqliteAdapterRef[T]):bool = self.supports_insert_on_conflict
proc supports_insert_on_duplicate_update*[T](self:ptr SqliteAdapterRef[T]):bool = self.supports_insert_on_conflict
proc supports_insert_conflict_target*[T](self:ptr SqliteAdapterRef[T]):bool = self.supports_insert_on_conflict
proc supports_index_sort_order*[T](self:ptr SqliteAdapterRef[T]):bool = true
proc encoding*[T](self:ptr SqliteAdapterRef[T]):string = self.conn.getValue(sql"PRAGMA encoding;")
proc supports_explain*[T](self:ptr SqliteAdapterRef[T]):bool = true
proc supports_lazy_transactions*[T](self:ptr SqliteAdapterRef[T]):bool = true

template disable_referential_integrity*[T](self:ptr SqliteAdapterRef[T],body:untyped) =
    let old_foreign_keys = self.conn.getValue(sql"PRAGMA foreign_keys")
    let old_defer_foreign_keys = self.conn.getValue(sql"PRAGMA defer_foreign_keys")
    self.conn.exec(sql"PRAGMA defer_foreign_keys = ON")
    self.conn.exec(sql"PRAGMA foreign_keys = OFF")
    body
    self.conn.exec(sql"PRAGMA defer_foreign_keys = ?",old_defer_foreign_keys)
    self.conn.exec(sql"PRAGMA foreign_keys = ?",old_foreign_keys)
      
