import os, macros, db_common, strutils
import ./db_adapterpkg/common
import ./db_adapterpkg/sqlite
import ./db_adapterpkg/mysql
import ./db_adapterpkg/postgres
import ./db_adapterpkg/odbc

{.experimental: "dotOperators".}

# follow design: https://github.com/rails/rails/blob/master/activerecord/lib/active_record/connection_adapters/abstract_adapter.rb
type DbConnection*[T] = object
        connection*: T
        # kind*:DriverKind
        case kind:DriverKind
          of DriverKind.sqlite:
            sqlite_adapter*:ptr SqliteAdapterRef[T]
          of DriverKind.mysql:
            mysql_adapter*:ptr MysqlAdapterRef[T]
          of DriverKind.postgres:
            postgres_adapter*:ptr PostgresAdapterRef[T]
          of DriverKind.odbc:
            odbc_adapter*:ptr OdbcAdapterRef[T]

proc implInitDbConnection*(args: varargs[string]): NimNode {.compileTime.} =
  let lib = ident(args[0])
  let driver_type = args[0][3..args[0].high]
  let myDbConn = nnkDotExpr.newTree(
      lib,
      newIdentNode("DbConn")
    )
  let callopen = nnkCall.newTree(
    nnkDotExpr.newTree(
      lib,
      newIdentNode("open")
    ),
    newStrLitNode args[1],
    newStrLitNode args[2],
    newStrLitNode args[3],
    newStrLitNode args[4]
  )
  let conn = ident("conn")
  let adapter = ident("adapter")

  let adapterConstruct = nnkCommand.newTree(
    newIdentNode("new"),
      nnkBracketExpr.newTree(
        newIdentNode(capitalizeAscii(driver_type) & "AdapterRef"),
        myDbConn
    ),

  )
  result = nnkStmtList.newTree(

    nnkImportStmt.newTree(
      lib
    ),
    nnkExportStmt.newTree(
      lib
    ),

    nnkVarSection.newTree(
      nnkIdentDefs.newTree(
        conn,
        newEmptyNode(),
        callopen
      )
    ),

    nnkVarSection.newTree(
      nnkIdentDefs.newTree(
        adapter,
        newEmptyNode(),
        adapterConstruct
      )
    ),

    nnkStmtList.newTree(
    nnkAsgn.newTree(
      nnkDotExpr.newTree(
        adapter,
        newIdentNode("conn")
      ),
      conn
    )
  ),

    nnkObjConstr.newTree(
      nnkBracketExpr.newTree(
        newIdentNode("DbConnection"),
        myDbConn
    ),
    nnkExprColonExpr.newTree(
    newIdentNode("connection"),
    conn
  ),
  nnkExprColonExpr.newTree(
    newIdentNode("kind"),
    nnkDotExpr.newTree(
      ident("DriverKind"),
      newIdentNode(driver_type)
    ),
  ),

    nnkExprColonExpr.newTree(
      newIdentNode(driver_type & "adapter"),
      nnkCast.newTree(
        nnkPtrTy.newTree(
          nnkBracketExpr.newTree(
            newIdentNode(capitalizeAscii(driver_type) & "AdapterRef"),
            myDbConn
    )
  ),
        nnkDotExpr.newTree(
          adapter,
          newIdentNode("addr")
    )
  )

    ),
  )
  )


macro initDbConnection*(driver, host, username, password, database: static[
    string]): untyped =

  implInitDbConnection("db_" & driver, host, username, password, database)

macro unpackMethodVarargs*(connection: untyped; met: untyped; args: varargs[
    untyped]): untyped =
  result = newCall(nnkDotExpr.newTree(
    connection,
    met
  ))
  for i in 0 ..< args.len:
    result.add args[i]


template `.()`*[T](con: DbConnection[T]; met: untyped; args: varargs[
    untyped]): untyped =
  unpackMethodVarargs(con.connection, met, args)


proc raw_connection*[T](self: DbConnection[T]): T =
  self.connection

converter toSqliteAdapterRef[T](x: ptr AbstractAdapterRef[T]):ptr SqliteAdapterRef[T] =
  cast[ptr SqliteAdapterRef[T]](x)

converter toMysqlAdapterRef[T](x: ptr AbstractAdapterRef[T]):ptr MysqlAdapterRef[T] =
  cast[ptr MysqlAdapterRef[T]](x)

converter toPostgresAdapterRef[T](x: ptr AbstractAdapterRef[T]):ptr PostgresAdapterRef[T] =
  cast[ptr PostgresAdapterRef[T]](x)

converter toOdbcAdapterRef[T](x: ptr AbstractAdapterRef[T]):ptr OdbcAdapterRef[T] =
  cast[ptr OdbcAdapterRef[T]](x)

proc get_adapter*[T](self: DbConnection[T]): auto =
  case self.kind:
    of DriverKind.sqlite:
      self.sqlite_adapter
    of DriverKind.mysql:
      self.mysql_adapter
    of DriverKind.postgres:
      self.postgres_adapter
    of DriverKind.odbc:
      self.odbc_adapter

proc get_database_version*[T](self: DbConnection[T]): int =
  self.get_adapter.get_database_version 

when isMainModule:
  dumpAstGen:
    # cast[ptr SqliteAdapterRef[T]](self.adapter)
    adapter.conn = conn
  let db = initDbConnection("sqlite", ":memory:", "", "", "")
  db.exec(sql"DROP TABLE IF EXISTS my_table")
  db.exec(sql"""CREATE TABLE my_table (
                  id   INTEGER,
                  name VARCHAR(50) NOT NULL
                )""")
  db.exec(sql"INSERT INTO my_table (id, name) VALUES (0, ?)",
  "Jack")
  assert db.get_database_version == 1
  assert db.kind == DriverKind.sqlite
  db.close()
