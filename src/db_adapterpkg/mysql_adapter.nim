import db_common
import ./common
import db_mysql,mysql
import nre

type MysqlAdapter*[T] = object of AbstractAdapter[T]
    full_version_string:string
type MysqlAdapterRef*[T] = ref MysqlAdapter[T]

proc  version_string(full_version_string:string):string  =
    full_version_string.match(re"^(?:5\.5\.5-)?(\d+\.\d+\.\d+)").get.captures[1]
    
proc full_version*[T](self:ptr MysqlAdapterRef[T]): string {.cached_property: "full_version_string".}= 
    result = PMySQL(self.db).get_server_version

proc get_database_version*[T](self:ptr MysqlAdapterRef[T]):Version {.cached_property: "database_version".} = 
    let version_string = version_string(self.full_version)
    Version(version_string)

proc mariadb*[T](self:ptr MysqlAdapterRef[T]):bool = 
    self.full_version.match(re"(?i)mariadb").isSome

proc supports_bulk_alter*[T](self:ptr MysqlAdapterRef[T]):bool = true

proc supports_index_sort_order*[T](self:ptr MysqlAdapterRef[T]):bool = 
    not self.mariadb and self.database_version >= "8.0.1"

proc supports_expression_index*[T](self:ptr MysqlAdapterRef[T]):bool = 
    not self.mariadb and self.database_version >= "8.0.13"

proc supports_transaction_isolation*[T](self:ptr MysqlAdapterRef[T]):bool = true

proc supports_explain*[T](self:ptr MysqlAdapterRef[T]):bool = true

proc supports_indexes_in_create*[T](self:ptr MysqlAdapterRef[T]):bool = true

proc supports_foreign_keys*[T](self:ptr MysqlAdapterRef[T]):bool = true

proc supports_views*[T](self:ptr MysqlAdapterRef[T]):bool = true

proc supports_datetime_with_precision*[T](self:ptr MysqlAdapterRef[T]):bool = 
    self.mariadb or self.database_version >= "5.6.4"

proc supports_virtual_columns*[T](self:ptr MysqlAdapterRef[T]):bool = 
    self.mariadb or self.database_version >= "5.7.5"

# See https://dev.mysql.com/doc/refman/8.0/en/optimizer-hints.html for more details.
proc supports_optimizer_hints*[T](self:ptr MysqlAdapterRef[T]):bool = 
    not self.mariadb and self.database_version >= "5.7.7"

proc supports_common_table_expressions*[T](self:ptr MysqlAdapterRef[T]):bool = 
    if self.mariadb:
        self.database_version >= "10.2.1"
    else:
        self.database_version >= "8.0.1"

proc supports_advisory_locks*[T](self:ptr MysqlAdapterRef[T]):bool = true


proc supports_insert_on_duplicate_skip*[T](self:ptr MysqlAdapterRef[T]):bool = true


proc supports_insert_on_duplicate_update*[T](self:ptr MysqlAdapterRef[T]):bool = true

# https://github.com/rails/rails/tree/f33d52c95217212cbacc8d5e44b5a8e3cdc6f5b3/activerecord/lib/active_record/connection_adapters#L133