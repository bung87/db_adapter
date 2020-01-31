import ../../common
import regex
import db_common
import sequtils,strutils
# https://github.com/rails/rails/blob/98a57aa5f610bc66af31af409c72173cdeeb3c9e/activerecord/lib/activeRecord/connectionAdapters/mysql/databaseStatements.rb
const dEFAULTREADQUERY = ["begin","commit", "explain", "release", "rollback", "savepoint", "select", "with"]

const cOMMENTREGEX = r"\*(?:[^\*]|\*[^/])*\*"

proc buildReadQueryRegexp(args:varargs[string]): Regex =
    var parts = newSeq[string]()
    parts.add args
    parts.add dEFAULTREADQUERY
    re (r"\A(?:[\(\s]|" & cOMMENTREGEX & ")*" & parts.mapIt( "((?i)" & it & ")" ).join("|") )

let rEADQUERY = buildReadQueryRegexp("begin", "commit", "explain", "select", "set", "show", "release", "savepoint", "rollback")

proc writeQuery(sql:string): bool =
    
    not sql.contains(rEADQUERY)

proc writeQuery*[T](self: ptr MysqlAdapterRef[T],sql:SqlQuery): bool =
    writeQuery(sql.string)

proc maxAllowedPacket*[T](self: ptr MysqlAdapterRef[T]): string =
    self.showVariable("maxAllowedPacket")
   

when isMainModule:
    assert writeQuery("SELECT * FROM") == false
    assert writeQuery("DROP INDEX") == true

