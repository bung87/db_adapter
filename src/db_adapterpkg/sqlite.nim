import db_common
import ./common
import os
import macros
import ./utils
import sequtils

# https://github.com/rails/rails/blob/f33d52c95217212cbacc8d5e44b5a8e3cdc6f5b3/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb
type SqliteAdapter*[T] = object of AbstractAdapter[T]
    
type SqliteAdapterRef*[T] = ref SqliteAdapter[T]


# https://github.com/nim-lang/Nim/blob/version-1-0/lib/impure/db_sqlite.nim#L306
# https://github.com/rails/rails/blob/f33d52c95217212cbacc8d5e44b5a8e3cdc6f5b3/activerecord/lib/active_record/connection_adapters/sqlite3_adapter.rb#L64
proc get_database_version*[T](self:ptr SqliteAdapterRef[T]):Version {.cached_property:"database_version",tags: [ReadDbEffect].}=
    Version(self.conn.getValue(sql"SELECT sqlite_version(*);"))

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
proc encoding*[T](self:ptr SqliteAdapterRef[T]):string {.tags: [ReadDbEffect].}= self.conn.getValue(sql"PRAGMA encoding;")
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

# DATABASE STATEMENTS ======================================

proc explain*[T](self:ptr SqliteAdapterRef[T],query: SqlQuery, args: varargs[string, `$`]):string {.tags: [ReadDbEffect].}=
    var q = dbFormat(query, args)
    let rows = self.conn.getAllRows sql("EXPLAIN QUERY PLAN " & q ) 
    for row in rows:
        result.add row.join("|")
        result.add "\n"
    result.add "\n"

# SCHEMA STATEMENTS ========================================

proc table_create_statment*[T](self:ptr SqliteAdapterRef[T],table_name:string):string{.tags: [ReadDbEffect].} = 
    # Result will have following sample string
    # CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    #                       "password_digest" varchar COLLATE "NOCASE");
    let rows = self.conn.getAllRows(sql("""SELECT sql FROM
              (SELECT * FROM sqlite_master UNION ALL
               SELECT * FROM sqlite_temp_master)
            WHERE type = 'table' AND name = ? """),table_name)
    result = rows[0].join("") & ";"

proc table_structure*[T](self:ptr SqliteAdapterRef[T],table_name:string):seq[seq[string]] {.tags: [ReadDbEffect].} = 
    # @[@["0", "id", "INTEGER", "0", "", "0"], @["1", "name", "VARCHAR(50)", "1", "", "0"]]
    # cid      name          type     notnull  dflt_value  pk   
    result = self.conn.getAllRows(sql"PRAGMA table_info(?)",table_name)


proc table_indexs*[T](self:ptr SqliteAdapterRef[T],table_name:string):seq[seq[string]] {.tags: [ReadDbEffect].} = 
    # type                    name                tbl_name    rootpage    sql
    result = self.conn.getAllRows(sql"SELECT * FROM sqlite_master WHERE type = ? AND tbl_name = ? ","index",table_name)


# proc table_structure(table_name)
#     structure = exec_query("PRAGMA table_info(?)",table_name)
#     # raise(ActiveRecord::StatementInvalid, "Could not find table '#{table_name}'") if structure.empty?
#     table_structure_with_collation(table_name, structure)
# end
proc primary_keys*[T](self:ptr SqliteAdapterRef[T],table_name:string):seq[string]{.tags: [ReadDbEffect].} = 
    let rows = self.table_structure(table_name)
    result = rows.filterIt( it[5] == "1").mapIt( it[1])

proc remove_index*[T](self:ptr SqliteAdapterRef[T],index_name:string) {.tags: [WriteDbEffect].} =
    self.conn.exec sql("DROP INDEX " & index_name)
    