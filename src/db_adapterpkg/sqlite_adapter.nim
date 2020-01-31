import db_common
import ./common
import os
import macros
import ./utils
import sequtils

# https://github.com/rails/rails/blob/f33d52c95217212cbacc8d5e44b5a8e3cdc6f5b3/activerecord/lib/activeRecord/connectionAdapters/sqlite3Adapter.rb



# https://github.com/nim-lang/Nim/blob/version-1-0/lib/impure/dbSqlite.nim#L306
# https://github.com/rails/rails/blob/f33d52c95217212cbacc8d5e44b5a8e3cdc6f5b3/activerecord/lib/activeRecord/connectionAdapters/sqlite3Adapter.rb#L64
proc getDatabaseVersion*[T](self: ptr SqliteAdapterRef[T]): Version {.
        cachedProperty: "databaseVersion", tags: [ReadDbEffect].} =
    Version(self.conn.getValue(sql"SELECT sqliteVersion(*);"))

proc databaseExists*[T](self: ptr SqliteAdapterRef[T]): bool =
    if self.config[].host == ":memory:":
        return true
    else:
        return fileExists(self.config[].host)
# databaseVersion in schemaCache https://github.com/rails/rails/blob/96289cfb9b6aeb8f1a917f892148fd47f2f2049a/activerecord/lib/activeRecord/connectionAdapters/schemaCache.rb#L33
proc supportsDdlTransactions*[T](self: ptr SqliteAdapterRef[T]): bool = true
proc supportsSavepoints*[T](self: ptr SqliteAdapterRef[T]): bool = true
proc supportsExpressionIndex*[T](self: ptr SqliteAdapterRef[
        T]): bool = self.databaseVersion >= "3.9.0"
proc requiresReloading*[T](self: ptr SqliteAdapterRef[T]): bool = true
proc supportsForeignKeys*[T](self: ptr SqliteAdapterRef[T]): bool = true
proc supportsViews*[T](self: ptr SqliteAdapterRef[T]): bool = true
proc supportsDatetimeWithPrecision*[T](self: ptr SqliteAdapterRef[
        T]): bool = true
proc supportsJson*[T](self: ptr SqliteAdapterRef[T]): bool = true
proc supportsCommonTableExpressions*[T](self: ptr SqliteAdapterRef[
        T]): bool = self.databaseVersion >= "3.8.3"
proc supportsInsertOnConflict*[T](self: ptr SqliteAdapterRef[
        T]): bool = self.databaseVersion >= "3.24.0"
proc supportsInsertOnDuplicateSkip*[T](self: ptr SqliteAdapterRef[
        T]): bool = self.supportsInsertOnConflict
proc supportsInsertOnDuplicateUpdate*[T](self: ptr SqliteAdapterRef[
        T]): bool = self.supportsInsertOnConflict
proc supportsInsertConflictTarget*[T](self: ptr SqliteAdapterRef[
        T]): bool = self.supportsInsertOnConflict
proc supportsIndexSortOrder*[T](self: ptr SqliteAdapterRef[T]): bool = true
proc encoding*[T](self: ptr SqliteAdapterRef[T]): string {.tags: [
        ReadDbEffect].} = self.conn.getValue(sql"PRAGMA encoding;")
proc supportsExplain*[T](self: ptr SqliteAdapterRef[T]): bool = true
proc supportsLazyTransactions*[T](self: ptr SqliteAdapterRef[T]): bool = true


template disableReferentialIntegrity*[T](self: ptr SqliteAdapterRef[T],
        body: untyped) =
    let oldForeignKeys = self.conn.getValue(sql"PRAGMA foreignKeys")
    let oldDeferForeignKeys = self.conn.getValue(sql"PRAGMA deferForeignKeys")
    self.conn.exec(sql"PRAGMA deferForeignKeys = ON")
    self.conn.exec(sql"PRAGMA foreignKeys = OFF")
    body
    self.conn.exec(sql"PRAGMA deferForeignKeys = ?", oldDeferForeignKeys)
    self.conn.exec(sql"PRAGMA foreignKeys = ?", oldForeignKeys)

# DATABASE STATEMENTS ======================================

proc explain*[T](self: ptr SqliteAdapterRef[T], query: SqlQuery, args: varargs[
        string, `$`]): string {.tags: [ReadDbEffect].} =
    var q = dbFormat(query, args)
    let rows = self.conn.getAllRows sql("EXPLAIN QUERY PLAN " & q)
    for row in rows:
        result.add row.join("|")
        result.add "\n"
    result.add "\n"

# SCHEMA STATEMENTS ========================================

proc tableCreateStatment*[T](self: ptr SqliteAdapterRef[T],
        tableName: string): string{.tags: [ReadDbEffect].} =
    # Result will have following sample string
    # CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    #                       "passwordDigest" varchar COLLATE "NOCASE");
    let rows = self.conn.getAllRows(sql(
            """SELECT sql FROM
              (SELECT * FROM sqliteMaster UNION ALL
               SELECT * FROM sqliteTempMaster)
            WHERE type = 'table' AND name = ? """), tableName)
    result = rows[0].join("") & ";"

proc tableStructure*[T](self: ptr SqliteAdapterRef[T],
        tableName: string): seq[seq[string]] {.tags: [ReadDbEffect].} =
    # @[@["0", "id", "INTEGER", "0", "", "0"], @["1", "name", "VARCHAR(50)", "1", "", "0"]]
    # cid      name          type     notnull  dfltValue  pk
    result = self.conn.getAllRows(sql"PRAGMA tableInfo(?)", tableName)


proc tableIndexs*[T](self: ptr SqliteAdapterRef[T], tableName: string): seq[
        seq[string]] {.tags: [ReadDbEffect].} =
    # type                    name                tblName    rootpage    sql
    result = self.conn.getAllRows(sql"SELECT * FROM sqliteMaster WHERE type = ? AND tblName = ? ",
            "index", tableName)


# proc tableStructure(tableName)
#     structure = execQuery("PRAGMA tableInfo(?)",tableName)
#     # raise(ActiveRecord::StatementInvalid, "Could not find table '#{tableName}'") if structure.empty?
#     tableStructureWithCollation(tableName, structure)
# end
proc primaryKeys*[T](self: ptr SqliteAdapterRef[T], tableName: string): seq[
        string] {.tags: [ReadDbEffect].} =
    let rows = self.tableStructure(tableName)
    result = rows.filterIt(it[5] == "1").mapIt(it[1])

proc removeIndex*[T](self: ptr SqliteAdapterRef[T], indexName: string) {.
        tags: [WriteDbEffect].} =
    self.conn.exec sql("DROP INDEX " & indexName)

proc foreignKeys*[T](self: ptr SqliteAdapterRef[T], tableName: string): seq[
        seq[string]] {.tags: [ReadDbEffect].} =
    self.conn.getAllRows(sql"PRAGMA foreignKeyList(?)", tableName)
