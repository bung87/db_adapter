import db_common
import ./common
import db_mysql, mysql
import nre
import times
import terminaltables
import strutils
import strscans

type transaction_isolation_levels* = enum
    read_uncommitted = "READ UNCOMMITTED"
    read_committed = "READ COMMITTED"
    repeatable_read =  "REPEATABLE READ"
    serializable =     "SERIALIZABLE"
 
proc version_string(full_version_string: string): string =
    var X,YY,ZZ:int
    discard scanf(full_version_string, "${ndigits(1)}${ndigits(2)}${ndigits(2)}", X, YY, ZZ)
    result = [X,YY,ZZ].join(".")

proc full_version*[T](self: ptr MysqlAdapterRef[T]): string {.
        cached_property: "full_version_string".} =
    result = PMySQL(self.conn).get_server_version.intToStr

proc get_database_version*[T](self: ptr MysqlAdapterRef[T]): Version {.
        cached_property: "database_version".} =
    let version_string = version_string(self.full_version)
    Version(version_string)

proc database_exists*[T](self: ptr MysqlAdapterRef[T]): bool =
    try:
        let db = open(self.config[].host, self.config[].username, self.config[].password,
                self.config[].database)
        result = true
    except:
        result = false

proc mariadb*[T](self: ptr MysqlAdapterRef[T]): bool =
    self.full_version.match(re"(?i)mariadb").isSome

proc supports_bulk_alter*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supports_index_sort_order*[T](self: ptr MysqlAdapterRef[T]): bool =
    not self.mariadb and self.database_version >= "8.0.1"

proc supports_expression_index*[T](self: ptr MysqlAdapterRef[T]): bool =
    not self.mariadb and self.database_version >= "8.0.13"

proc supports_transaction_isolation*[T](self: ptr MysqlAdapterRef[
        T]): bool = true

proc supports_explain*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supports_indexes_in_create*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supports_foreign_keys*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supports_views*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supports_datetime_with_precision*[T](self: ptr MysqlAdapterRef[T]): bool =
    self.mariadb or self.database_version >= "5.6.4"

proc supports_virtual_columns*[T](self: ptr MysqlAdapterRef[T]): bool =
    self.mariadb or self.database_version >= "5.7.5"

# See https://dev.mysql.com/doc/refman/8.0/en/optimizer-hints.html for more details.
proc supports_optimizer_hints*[T](self: ptr MysqlAdapterRef[T]): bool =
    not self.mariadb and self.database_version >= "5.7.7"

proc supports_common_table_expressions*[T](self: ptr MysqlAdapterRef[T]): bool =
    if self.mariadb:
        self.database_version >= "10.2.1"
    else:
        self.database_version >= "8.0.1"

proc supports_advisory_locks*[T](self: ptr MysqlAdapterRef[T]): bool = true


proc supports_insert_on_duplicate_skip*[T](self: ptr MysqlAdapterRef[
        T]): bool = true


proc supports_insert_on_duplicate_update*[T](self: ptr MysqlAdapterRef[
        T]): bool = true

# mysql2_adapter

proc supports_json*[T](self: ptr MysqlAdapterRef[T]): bool =
    self.mariadb and self.database_version >= "5.7.8"


proc supports_comments*[T](self: ptr MysqlAdapterRef[T]): bool = true


proc supports_comments_in_create*[T](self: ptr MysqlAdapterRef[T]): bool = true


proc supports_savepoints*[T](self: ptr MysqlAdapterRef[T]): bool = true


proc supports_lazy_transactions*[T](self: ptr MysqlAdapterRef[T]): bool = true

template disable_referential_integrity *[T](self: ptr MysqlAdapterRef[T],body: untyped) =
    
    old = self.conn.getValue(sql("SELECT @@FOREIGN_KEY_CHECKS"))
    self.conn.exec(sql"SET FOREIGN_KEY_CHECKS = 0")
    body
    self.conn.exec(sql"SET FOREIGN_KEY_CHECKS = ?",old)


# DATABASE STATEMENTS ======================================
# https://github.com/xmonader/nim-terminaltables
# https://github.com/rails/rails/blob/98a57aa5f610bc66af31af409c72173cdeeb3c9e/activerecord/lib/active_record/connection_adapters/mysql/explain_pretty_printer.rb#L6

proc explain*[T](self: ptr MysqlAdapterRef[T], query: SqlQuery, args: varargs[
    string, `$`]): string {.tags: [ReadDbEffect].} =
    var q = dbFormat(query, args)
    let rows = self.conn.getAllRows sql("EXPLAIN " & q)
    let start   = cpuTime()
    var t = newUnicodeTable()
    t.setHeaders(@["ID", "Name", "Fav animal", "Date", "OK"])
    t.addRow(@["1", "xmonader", "Cat, Dog", "2018-10-2", "yes"])
    t.addRow(@["2", "ahmed", "Shark", "2018-10-2", "yes"])
    t.addRow(@["3", "dr who", "Humans", "1018-5-2", "no"])
    let table = render(t)
    # 2 rows in set (0.00 sec)
    let elapsed = initDuration(seconds = cpuTime() - start).inSeconds

# https://github.com/rails/rails/tree/f33d52c95217212cbacc8d5e44b5a8e3cdc6f5b3/activerecord/lib/active_record/connection_adapters#L133

proc begin_db_transaction*[T](self: ptr MysqlAdapterRef[T]) = 
        self.conn.exec "BEGIN"
      

proc begin_isolated_db_transaction*[T](self: ptr MysqlAdapterRef[T],isolation:transaction_isolation_levels) = 
    self.conn.exec "SET TRANSACTION ISOLATION LEVEL " & $isolation
    self.begin_db_transaction


proc commit_db_transaction*[T](self: ptr MysqlAdapterRef[T]) =
    self.conn.exec "COMMIT"


proc exec_rollback_db_transaction*[T](self: ptr MysqlAdapterRef[T]) =
    self.conn.exec "ROLLBACK"


proc empty_insert_statement_value*[T](self: ptr MysqlAdapterRef[T],primary_key:string):string = 
    "VALUES ()"
    
# SCHEMA STATEMENTS ========================================

proc drop_database*[T](self: ptr MysqlAdapterRef[T],name:string) =
    self.conn.exec sql"DROP DATABASE IF EXISTS ? ",name


proc current_database*[T](self: ptr MysqlAdapterRef[T]): string =
    self.conn.getValue(sql"SELECT database()")

# Returns the database character set.
proc charset*[T](self: ptr MysqlAdapterRef[T]): string =
    self.show_variable "character_set_database"

# Returns the database collation strategy.
proc collation*[T](self: ptr MysqlAdapterRef[T]): string =
    self.show_variable "collation_database"

# proc table_comment*[T](self: ptr MysqlAdapterRef[T],table_name:string): string =
# TABLE_SCHEMA The name of the schema (database) to which the table belongs.
#     scope = quoted_scope(table_name)

#     query_value(<<~SQL, "SCHEMA").presence
#     SELECT table_comment
#     FROM information_schema.tables
#     WHERE table_schema = #{scope[:schema]}
#         AND table_name = #{scope[:name]}
#     SQL


# def change_table_comment(table_name, comment_or_changes) # :nodoc:
# comment = extract_new_comment_value(comment_or_changes)
# comment = "" if comment.nil?
# execute("ALTER TABLE #{quote_table_name(table_name)} COMMENT #{quote(comment)}")
# end

# SHOW VARIABLES LIKE 'name'
proc show_variable*[T](self: ptr MysqlAdapterRef[T],name:string): string =
    self.conn.getValue( sql("SELECT @@" & name) )
    
proc supports_rename_index*[T](self: ptr MysqlAdapterRef[T]): bool = 
    if self.mariadb:
        false 
    else:
        self.database_version >= "5.7.6"

when isMainModule:
    let v = 50730.intToStr
    assert version_string(v) == "5.7.30"
    