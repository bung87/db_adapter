import ../../common
import nre
import db_common
import sequtils,strutils
# https://github.com/rails/rails/blob/98a57aa5f610bc66af31af409c72173cdeeb3c9e/activerecord/lib/active_record/connection_adapters/mysql/database_statements.rb
const DEFAULT_READ_QUERY = ["begin","commit", "explain", "release", "rollback", "savepoint", "select", "with"]

const COMMENT_REGEX = r"\*(?:[^\*]|\*[^/])*\*"

proc build_read_query_regexp(args:varargs[string]): Regex =
    var parts = newSeq[string]()
    parts.add args
    parts.add DEFAULT_READ_QUERY
    re (r"\A(?:[\(\s]|" & COMMENT_REGEX & ")*" & parts.mapIt( "((?i)" & it & ")" ).join("|") )

let READ_QUERY = build_read_query_regexp("begin", "commit", "explain", "select", "set", "show", "release", "savepoint", "rollback")

proc write_query(sql:string): bool =
    
    not sql.match(READ_QUERY).isSome

proc write_query*[T](self: ptr MysqlAdapterRef[T],sql:SqlQuery): bool =
    write_query(sql.string)

proc max_allowed_packet*[T](self: ptr MysqlAdapterRef[T]): string =
    self.show_variable("max_allowed_packet")
   

when isMainModule:
    assert write_query("SELECT * FROM") == false
    assert write_query("DROP INDEX") == true

