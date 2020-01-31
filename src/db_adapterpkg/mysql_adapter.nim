import db_common
import ./common
import db_mysql, mysql
import regex
import times
import terminaltables
import strutils
import os, std/monotimes
import sequtils

include private/mysql/schema_statements
include private/mysql/quoting

type transactionIsolationLevels* = enum
    readUncommitted = "READ UNCOMMITTED"
    readCommitted = "READ COMMITTED"
    repeatableRead = "REPEATABLE READ"
    serializable = "SERIALIZABLE"

type Options = object
    collation: string
    charset: string
 # proc versionString(fullVersionString: string): string =
 #     # "50730" pyMysql(self.conn).getServerVersion
 #     var X,YY,ZZ:int
 #     discard scanf(fullVersionString, "${ndigits(1)}${ndigits(2)}${ndigits(2)}", X, YY, ZZ)
 #     result = [X,YY,ZZ].join(".")

proc versionString(fullVersionString: string): string =
    # 5.7.27-0ubuntu0.18.04.1
    var m: regex.RegexMatch
    discard fullVersionString.match(re"^(?:5\.5\.5-)?(\d+\.\d+\.\d+)",m)
    fullVersionString[m.group(1)[0]]

proc fullVersion*[T](self: ptr MysqlAdapterRef[T]): string {.
        cachedProperty: "fullVersionString".} =
    result = $(cast[ptr St_mysql](self.conn).getServerInfo)

proc getDatabaseVersion*[T](self: ptr MysqlAdapterRef[T]): Version {.
        cachedProperty: "databaseVersion".} =
    let versionString = versionString(self.fullVersion)
    Version(versionString)

proc databaseExists*[T](self: ptr MysqlAdapterRef[T]): bool =
    try:
        let db = open(self.config[].host, self.config[].username, self.config[
            ].password, self.config[].database)
        result = true
    except:
        result = false

proc mariadb*[T](self: ptr MysqlAdapterRef[T]): bool =
    self.fullVersion.match(re"(?i)mariadb").isSome

proc supportsBulkAlter*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supportsIndexSortOrder*[T](self: ptr MysqlAdapterRef[T]): bool =
    not self.mariadb and self.databaseVersion >= "8.0.1"

proc supportsExpressionIndex*[T](self: ptr MysqlAdapterRef[T]): bool =
    not self.mariadb and self.databaseVersion >= "8.0.13"

proc supportsTransactionIsolation*[T](self: ptr MysqlAdapterRef[
        T]): bool = true

proc supportsExplain*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supportsIndexesInCreate*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supportsForeignKeys*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supportsViews*[T](self: ptr MysqlAdapterRef[T]): bool = true

proc supportsDatetimeWithPrecision*[T](self: ptr MysqlAdapterRef[T]): bool =
    self.mariadb or self.databaseVersion >= "5.6.4"

proc supportsVirtualColumns*[T](self: ptr MysqlAdapterRef[T]): bool =
    self.mariadb or self.databaseVersion >= "5.7.5"

# See https://dev.mysql.com/doc/refman/8.0/en/optimizer-hints.html for more details.
proc supportsOptimizerHints*[T](self: ptr MysqlAdapterRef[T]): bool =
    not self.mariadb and self.databaseVersion >= "5.7.7"

proc supportsCommonTableExpressions*[T](self: ptr MysqlAdapterRef[T]): bool =
    if self.mariadb:
        self.databaseVersion >= "10.2.1"
    else:
        self.databaseVersion >= "8.0.1"

proc supportsAdvisoryLocks*[T](self: ptr MysqlAdapterRef[T]): bool = true


proc supportsInsertOnDuplicateSkip*[T](self: ptr MysqlAdapterRef[
        T]): bool = true


proc supportsInsertOnDuplicateUpdate*[T](self: ptr MysqlAdapterRef[
        T]): bool = true

# mysql2Adapter

proc supportsJson*[T](self: ptr MysqlAdapterRef[T]): bool =
    self.mariadb and self.databaseVersion >= "5.7.8"


proc supportsComments*[T](self: ptr MysqlAdapterRef[T]): bool = true


proc supportsCommentsInCreate*[T](self: ptr MysqlAdapterRef[T]): bool = true


proc supportsSavepoints*[T](self: ptr MysqlAdapterRef[T]): bool = true


proc supportsLazyTransactions*[T](self: ptr MysqlAdapterRef[T]): bool = true

template disableReferentialIntegrity *[T](self: ptr MysqlAdapterRef[T],
        body: untyped) =

    old = self.conn.getValue(sql("SELECT @@fOREIGNKEYCHECKS"))
    self.conn.exec(sql"SET fOREIGNKEYCHECKS = 0")
    body
    self.conn.exec(sql"SET fOREIGNKEYCHECKS = ?", old)


# DATABASE STATEMENTS ======================================
# https://github.com/xmonader/nim-terminaltables
# https://github.com/rails/rails/blob/98a57aa5f610bc66af31af409c72173cdeeb3c9e/activerecord/lib/activeRecord/connectionAdapters/mysql/explainPrettyPrinter.rb#L6

proc explain*[T](self: ptr MysqlAdapterRef[T], query: SqlQuery, args: varargs[
    string, `$`]): string {.tags: [ReadDbEffect].} =
    var q = dbFormat(query, args)
    let start = getMonoTime()
    let rows = self.conn.getAllRows sql("EXPLAIN " & q)
    let elapsed = getMonoTime() - start
    let sec = elapsed.inMilliseconds.BiggestFloat / 1000.0
    var t = newUnicodeTable()
    t.setHeaders(@["id", "selectType", "table", "type", "possibleKeys", "key",
            "keyLen", "ref", "rows", "Extra"])
    t.addRows(rows)
    let table = render(t)
    # 2 rows in set (0.00 sec)
    result = table & "$1 rows in set ($2 sec)" % [len(rows), sec.formatFloat(
            ffDecimal, 2)]



# https://github.com/rails/rails/tree/f33d52c95217212cbacc8d5e44b5a8e3cdc6f5b3/activerecord/lib/activeRecord/connectionAdapters#L133

proc beginDbTransaction*[T](self: ptr MysqlAdapterRef[T]) =
    self.conn.exec "BEGIN"


proc beginIsolatedDbTransaction*[T](self: ptr MysqlAdapterRef[T],
        isolation: transactionIsolationLevels) =
    self.conn.exec "SET TRANSACTION ISOLATION LEVEL " & $isolation
    self.beginDbTransaction


proc commitDbTransaction*[T](self: ptr MysqlAdapterRef[T]) =
    self.conn.exec "COMMIT"


proc execRollbackDbTransaction*[T](self: ptr MysqlAdapterRef[T]) =
    self.conn.exec "ROLLBACK"


proc emptyInsertStatementValue*[T](self: ptr MysqlAdapterRef[T],
        primaryKey: string): string =
    "VALUES ()"

# SCHEMA STATEMENTS ========================================

proc createDatabase*[T](self: ptr MysqlAdapterRef[T], name: string,
        options: Options) =
    if options.collation.len > 0:
        self.conn.exec sql("CREATE DATABASE $1 DEFAULT COLLATE $2" % [
                quoteTableName(name), quoteTableName(options.collation)])
    elif options.charset.len > 0:
        self.conn.exec sql("CREATE DATABASE $1 DEFAULT CHARACTER SET $2" % [
                quoteTableName(name), quoteTableName(options.charset)])
    elif self.rowFormatDynamicByDefault:
        self.conn.exec "CREATE DATABASE $1 DEFAULT CHARACTER SET `utf8mb4`" %
                quoteTableName(name)
    else:
        raise newException(ValueError, "Configure a supported :charset and ensure innodbLargePrefix is enabled to support indexes on varchar(255) string columns.")


proc dropDatabase*[T](self: ptr MysqlAdapterRef[T], name: string) =
    self.conn.exec sql"DROP DATABASE IF EXISTS ? ", name


proc currentDatabase*[T](self: ptr MysqlAdapterRef[T]): string =
    self.conn.getValue(sql"SELECT database()")

# Returns the database character set.
proc charset*[T](self: ptr MysqlAdapterRef[T]): string =
    self.showVariable "characterSetDatabase"

# Returns the database collation strategy.
proc collation*[T](self: ptr MysqlAdapterRef[T]): string =
    self.showVariable "collationDatabase"

proc tableComment*[T](self: ptr MysqlAdapterRef[T],
        tableName: string): string =
    # tABLESCHEMA The name of the schema (database) to which the table belongs.
    let scope = quotedScope(tableName)

    self.conn.getValue(sql("""
    SELECT tableComment
    FROM informationSchema.tables
    WHERE tableSchema = $1
        AND tableName = $2
    """ % [scope.schema, scope.name]))


proc changeTableComment*[T](self: ptr MysqlAdapterRef[T], tableName: string,
        commentOrChanges: Change) =
    let comment = extractNewCommentValue(commentOrChanges)
    self.conn.exec("ALTER TABLE $1 COMMENT $2" % [quoteTableName(
            tableName), quote(comment)])

# SHOW VARIABLES LIKE 'name'
proc showVariable*[T](self: ptr MysqlAdapterRef[T], name: string): string =
    self.conn.getValue(sql("SELECT @@" & name))

proc supportsRenameIndex*[T](self: ptr MysqlAdapterRef[T]): bool =
    if self.mariadb:
        false
    else:
        self.databaseVersion >= "5.7.6"

proc createTableInfo*[T](self: ptr MysqlAdapterRef[T],
        tableName: string): string =
    self.conn.getRow(sql"SHOW CREATE TABLE $1" % quoteTableName(tableName))[1]


proc primaryKeys*[T](self: ptr MysqlAdapterRef[T], tableName: string): seq[
        string]{.tags: [ReadDbEffect].} =

    let scope = quotedScope(tableName)
    
    let rows = self.conn.getAllRows sql """
      SELECT columnName
      FROM informationSchema.statistics
      WHERE indexName = 'PRIMARY'
        AND tableSchema = $1
        AND tableName = $2
      ORDER BY seqInIndex
    """ % [scope.schema, scope.name]
    result = rows.mapIt(it[0])

proc strictMode*[T](self: ptr MysqlAdapterRef[T]):bool =
    self.config.strict == "true"

proc checkVersion*[T](self: ptr MysqlAdapterRef[T]) =
    if self.databaseVersion < "5.5.8":
      raise newException(ValueError,"Your version of MySQL ($1) is too old. Active Record supports MySQL >= 5.5.8." % self.databaseVersion)

when isMainModule:
    let adapter = new MysqlAdapterRef[dbMysql.DbConn]
    adapter.conn = dbMysql.open("localhost","","","cms")
    echo adapter.unsafeAddr.primaryKeys("authUser")