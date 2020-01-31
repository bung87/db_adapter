import db_common
import ./common
import strutils

proc supportsBulkAlter*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsIndexSortOrder*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsPartialIndex*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsExpressionIndex*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsTransactionIsolation*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc supportsForeignKeys*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsValidateConstraints*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc supportsViews*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsDatetimeWithPrecision*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc supportsJson*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsComments*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsSavepoints*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsInsertReturning*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsInsertOnConflict*[T](self: ptr PostgresAdapterRef[T]): bool =
    self.databaseVersion >= 90500

proc supportsInsertOnDuplicateSkip*[T](self: ptr PostgresAdapterRef[
        T]): bool = self.supportsInsertOnConflict

proc supportsInsertOnDuplicateUpdate*[T](self: ptr PostgresAdapterRef[
        T]): bool = self.supportsInsertOnDuplicateUpdate

proc supportsInsertConflictTarget*[T](self: ptr PostgresAdapterRef[
        T]): bool = self.supportsInsertOnConflict

proc setStandardConformingStrings*[T](self: ptr PostgresAdapterRef[T]): string =
    self.conn.exec(sql"SET standardConformingStrings = on")

proc supportsDdlTransactions*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsAdvisoryLocks*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsExplain*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsExtensions*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsMaterializedViews*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc supportsForeignTables*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supportsPgcryptoUuid*[T](self: ptr PostgresAdapterRef[T]): bool =
    self.databaseVersion >= 90400

proc supportsLazyTransactions*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc getAdvisoryLock*[T](self:ptr PostgresAdapterRef[T],lockId:int64) =
    self.conn.getValue("SELECT pgTryAdvisoryLock($1)" % lockId)

proc releaseAdvisoryLock*[T](self:ptr PostgresAdapterRef[T],lockId:int64) =
    self.conn.getValue("SELECT pgAdvisoryUnlock($1)" % lockId)

proc enableExtension*[T](self:ptr PostgresAdapterRef[T],name:string):seq[ seq[string]]  = 
    result = self.conn.getAllRows( sql("CREATE EXTENSION IF NOT EXISTS \"$1\"" % name)  )
    self.reloadTypeMap

proc disableExtension*[T](self:ptr PostgresAdapterRef[T],name:string):seq[ seq[string]] =
    self.conn.getAllRows( sql("DROP EXTENSION IF EXISTS \"$1\" CASCADE" % name) )
    self.reloadTypeMap

proc extensionAvailable*[T](self:ptr PostgresAdapterRef[T],name:string):bool =
    self.conn.getValue( sql("SELECT true FROM pgAvailableExtensions WHERE name = $1" % quote(name)) )

proc extensionEnabled*[T](self:ptr PostgresAdapterRef[T],name:string):bool =
    self.conn.getValue( sql("SELECT installedVersion IS NOT NULL FROM pgAvailableExtensions WHERE name = $1" % quote(name) ))

proc extensions*[T](self:ptr PostgresAdapterRef[T]):seq[seq[string]] =
    self.conn.getAllRows("SELECT extname FROM pgExtension").castValues

# Returns the configured supported identifier length supported by PostgreSQL
proc maxIdentifierLength*[T](self:ptr PostgresAdapterRef[T]):int =
    self.maxIdentifierLength or parseInt(self.conn.getValue("SHOW maxIdentifierLength"))
   
# Set the authorized user for this session
proc sessionAuth*[T](self:ptr PostgresAdapterRef[T],user:string) =
    # clearCache!
    self.conn.exec( sql("SET SESSION AUTHORIZATION $1" % user) )

# Returns the version of the connected PostgreSQL server.
proc getDatabaseVersion*[T](self:ptr PostgresAdapterRef[T]):Version = 
    # @connection.serverVersion
    discard
proc postgresqlVersion*[T](self:ptr PostgresAdapterRef[T]):Version =  self.databaseVersion

proc checkVersion*[T](self:ptr PostgresAdapterRef[T]) = 
    if self.databaseVersion < Version("9.3.0"): # 90300
        raise newException(ValueError,"Your version of PostgreSQL ($1) is too old. Active Record supports PostgreSQL >= 9.3." % self.databaseVersion)
