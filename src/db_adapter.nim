import os,macros,db_common,strutils
{.experimental: "dotOperators".}

# follow design: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb

type 
  DriverKind* {.pure.} = enum
    sqlite,
    mysql,
    postgres,
    odbc


type DbConnection*[T] = object
        connection:T


proc implInitDbConnection*(args:varargs[string]):NimNode {.compileTime.} =
  let lib = ident(args[0])
  let myDbConn = nnkDotExpr.newTree(
      lib,
      newIdentNode("DbConn")
    )
  let callopen =  nnkCall.newTree(
    nnkDotExpr.newTree(
      lib,
      newIdentNode("open")
    ),
    newStrLitNode args[1],
    newStrLitNode args[2],
    newStrLitNode args[3],
    newStrLitNode args[4]
  )
  result = nnkStmtList.newTree(
    nnkImportStmt.newTree(
      lib
    ),
    nnkExportStmt.newTree(
      lib
    ),
    nnkObjConstr.newTree(
      nnkBracketExpr.newTree(
        newIdentNode("DbConnection"),
        myDbConn
      ),
      nnkExprColonExpr.newTree(
        newIdentNode("connection"),
        callopen
      )
    )
  )

macro initDbConnection*(driver,host,username,password,database:static[string]):untyped =
  
  implInitDbConnection( "db_" & driver, host, username, password, database)

macro unpackMethodVarargs*(connection: untyped; met: untyped;args: varargs[untyped]): untyped =
  result = newCall(nnkDotExpr.newTree(
    connection,
    met
  ))
  for i in 0 ..< args.len:
    result.add args[i]


template `.()`*[T](con: DbConnection[T], met:untyped, args:varargs[untyped] ): untyped =  
  unpackMethodVarargs(con.connection,met,args )


proc raw_connection*[T](self:DbConnection[T]):T =
  self.connection

proc get_database_version*[T](self:DbConnection[T]):int =
  self.getValue(sql"PRAGMA schema_version;").parseInt

when isMainModule:
  let db = initDbConnection( "sqlite",":memory:","","","")
  db.exec(sql"DROP TABLE IF EXISTS my_table")
  db.exec(sql"""CREATE TABLE my_table (
                  id   INTEGER,
                  name VARCHAR(50) NOT NULL
                )""")
  db.exec(sql"INSERT INTO my_table (id, name) VALUES (0, ?)",
  "Jack")
  assert db.get_database_version == 1
  db.close()