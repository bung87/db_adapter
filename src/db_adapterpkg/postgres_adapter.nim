import db_common
import ./common
import strutils

proc supports_bulk_alter*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_index_sort_order*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_partial_index*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_expression_index*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_transaction_isolation*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc supports_foreign_keys*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_validate_constraints*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc supports_views*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_datetime_with_precision*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc supports_json*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_comments*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_savepoints*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_insert_returning*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_insert_on_conflict*[T](self: ptr PostgresAdapterRef[T]): bool =
    self.database_version >= 90500

proc supports_insert_on_duplicate_skip*[T](self: ptr PostgresAdapterRef[
        T]): bool = self.supports_insert_on_conflict

proc supports_insert_on_duplicate_update*[T](self: ptr PostgresAdapterRef[
        T]): bool = self.supports_insert_on_duplicate_update

proc supports_insert_conflict_target*[T](self: ptr PostgresAdapterRef[
        T]): bool = self.supports_insert_on_conflict

proc set_standard_conforming_strings*[T](self: ptr PostgresAdapterRef[T]): string =
    self.conn.exec(sql"SET standard_conforming_strings = on")

proc supports_ddl_transactions*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_advisory_locks*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_explain*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_extensions*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_materialized_views*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc supports_foreign_tables*[T](self: ptr PostgresAdapterRef[T]): bool = true

proc supports_pgcrypto_uuid*[T](self: ptr PostgresAdapterRef[T]): bool =
    self.database_version >= 90400

proc supports_lazy_transactions*[T](self: ptr PostgresAdapterRef[
        T]): bool = true

proc get_advisory_lock*[T](self:ptr PostgresAdapterRef[T],lock_id:int64) =
    self.conn.getValue("SELECT pg_try_advisory_lock($1)" % lock_id)

proc release_advisory_lock*[T](self:ptr PostgresAdapterRef[T],lock_id:int64) =
    self.conn.getValue("SELECT pg_advisory_unlock($1)" % lock_id)

proc enable_extension*[T](self:ptr PostgresAdapterRef[T],name:string):seq[ seq[string]]  = 
    result = self.conn.getAllRows( sql("CREATE EXTENSION IF NOT EXISTS \"$1\"" % name)  )
    self.reload_type_map

proc disable_extension*[T](self:ptr PostgresAdapterRef[T],name:string):seq[ seq[string]] =
    self.conn.getAllRows( sql("DROP EXTENSION IF EXISTS \"$1\" CASCADE" % name) )
    self.reload_type_map

proc extension_available*[T](self:ptr PostgresAdapterRef[T],name:string):bool =
    self.conn.getValue( sql("SELECT true FROM pg_available_extensions WHERE name = $1" % quote(name)) )

proc extension_enabled*[T](self:ptr PostgresAdapterRef[T],name:string):bool =
    self.conn.getValue( sql("SELECT installed_version IS NOT NULL FROM pg_available_extensions WHERE name = $1" % quote(name) ))

proc extensions*[T](self:ptr PostgresAdapterRef[T]):seq[seq[string]] =
    self.conn.getAllRows("SELECT extname FROM pg_extension").cast_values

# Returns the configured supported identifier length supported by PostgreSQL
proc max_identifier_length*[T](self:ptr PostgresAdapterRef[T]):int =
    self.max_identifier_length or parseInt(self.conn.getValue("SHOW max_identifier_length"))
   
# Set the authorized user for this session
proc session_auth*[T](self:ptr PostgresAdapterRef[T],user:string) =
    # clear_cache!
    self.conn.exec( sql("SET SESSION AUTHORIZATION $1" % user) )

# Returns the version of the connected PostgreSQL server.
proc get_database_version*[T](self:ptr PostgresAdapterRef[T]):Version = 
    # @connection.server_version
    discard
proc postgresql_version*[T](self:ptr PostgresAdapterRef[T]):Version =  self.database_version

proc check_version*[T](self:ptr PostgresAdapterRef[T]) = 
    if self.database_version < Version("9.3.0"): # 90300
        raise newException(ValueError,"Your version of PostgreSQL ($1) is too old. Active Record supports PostgreSQL >= 9.3." % self.database_version)
