import os, macros, db_common, strutils
import ./db_adapterpkg/common
import ./db_adapterpkg/sqlite_adapter
import ./db_adapterpkg/mysql_adapter
import ./db_adapterpkg/postgres_adapter
import ./db_adapterpkg/odbc_adapter
export sqlite_adapter,mysql_adapter,postgres_adapter,odbc_adapter,common

{.experimental: "dotOperators".}

# follow design: https://github.com/rails/rails/blob/master/activerecord/lib/activeRecord/connectionAdapters/abstractAdapter.rb

type DbConnection*[T] = object
        connection*: T
        config*:ptr DbConfigRef
        case kind:DriverKind
          of DriverKind.sqlite:
            sqliteAdapter*:ptr SqliteAdapterRef[T]
          of DriverKind.mysql:
            mysqlAdapter*:ptr MysqlAdapterRef[T]
          of DriverKind.postgres:
            postgresAdapter*:ptr PostgresAdapterRef[T]
          of DriverKind.odbc:
            odbcAdapter*:ptr OdbcAdapterRef[T]

proc implInitDbConnection*(args: varargs[string]): NimNode {.compileTime.} =
  let lib = ident(args[0])
  let driverType = args[0][3..args[0].high]
  let host = newStrLitNode args[1]
  let username = newStrLitNode args[2]
  let password = newStrLitNode args[3]
  let database = newStrLitNode args[4]
  let myDbConn = nnkDotExpr.newTree(
      lib,
      newIdentNode("DbConn")
    )
  let callopen = nnkCall.newTree(
    nnkDotExpr.newTree(
      lib,
      newIdentNode("open")
    ),
    host,
    username,
    password,
    database
  )
  let conn = ident("conn")
  let adapter = genSym(nskVar,"adapter")

  let adapterConstruct = nnkCommand.newTree(
    newIdentNode("new"),
      nnkBracketExpr.newTree(
        newIdentNode(capitalizeAscii(driverType) & "AdapterRef"),
        myDbConn
    ),
  )
  let configConstruct = nnkCommand.newTree(
    newIdentNode("new"),
    newIdentNode("DbConfigRef")
  )
  let config = gensym(nskVar,"config")

  let assignConfig = nnkStmtList.newTree(
    nnkAsgn.newTree(
      nnkDotExpr.newTree(
        config,
        newIdentNode("host")
      ),
      host
    )
    ,nnkAsgn.newTree(
      nnkDotExpr.newTree(
        config,
        newIdentNode("username")
      ),
      username
    ),
    nnkAsgn.newTree(
      nnkDotExpr.newTree(
        config,
        newIdentNode("password")
      ),
      password
    ),
    nnkAsgn.newTree(
      nnkDotExpr.newTree(
        config,
        newIdentNode("database")
      ),
      database
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

    nnkVarSection.newTree(
      nnkIdentDefs.newTree(
        config,
        newEmptyNode(),
        configConstruct
      )
    ),
    assignConfig,

    nnkStmtList.newTree(
    nnkAsgn.newTree(
      nnkDotExpr.newTree(
        adapter,
        newIdentNode("conn")
      ),
      conn
    ),

    nnkAsgn.newTree(
      nnkDotExpr.newTree(
        adapter,
        newIdentNode("config")
      ),
      nnkDotExpr.newTree(
        config,
        newIdentNode("addr")
        )
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
      newIdentNode(driverType)
    ),
  ),
  nnkExprColonExpr.newTree(
    newIdentNode("config"),
    nnkDotExpr.newTree(
          config,
          newIdentNode("addr")
    )
  ),

    nnkExprColonExpr.newTree(
      newIdentNode(driverType & "adapter"),
      nnkCast.newTree(
        nnkPtrTy.newTree(
          nnkBracketExpr.newTree(
            newIdentNode(capitalizeAscii(driverType) & "AdapterRef"),
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

macro unpackMethodVarargs*(obj: untyped; met: untyped; args: varargs[
    untyped]): untyped =
  result = newCall(nnkDotExpr.newTree(
    obj,
    met
  ))
  for i in 0 ..< args.len:
    result.add args[i]

macro unpackProperty*(obj: untyped; met: untyped;): untyped =
  nnkDotExpr.newTree(
    obj,
    met
  )

proc adapter*[T](self: DbConnection[T]): auto =
  case self.kind:
    of DriverKind.sqlite:
      self.sqliteAdapter
    of DriverKind.mysql:
      self.mysqlAdapter
    of DriverKind.postgres:
      self.postgresAdapter
    of DriverKind.odbc:
      self.odbcAdapter

template `.`*[T](con: DbConnection[T]; met: untyped; args: varargs[
    untyped]): untyped =
  when compiles(unpackMethodVarargs(con.connection, met, args)):
    unpackMethodVarargs(con.connection, met, args)
  elif compiles(unpackMethodVarargs(con.adapter, met, args)):
    unpackMethodVarargs(con.adapter, met, args)
  elif compiles(unpackProperty(con.adapter, met)):
    unpackProperty(con.adapter, met)

proc rawConnection*[T](self: DbConnection[T]): T =
  self.connection

converter toSqliteAdapterRef*[T](x: ptr AbstractAdapterRef[T]):ptr SqliteAdapterRef[T] =
  cast[ptr SqliteAdapterRef[T]](x)

converter toMysqlAdapterRef*[T](x: ptr AbstractAdapterRef[T]):ptr MysqlAdapterRef[T] =
  cast[ptr MysqlAdapterRef[T]](x)

converter toPostgresAdapterRef*[T](x: ptr AbstractAdapterRef[T]):ptr PostgresAdapterRef[T] =
  cast[ptr PostgresAdapterRef[T]](x)

converter toOdbcAdapterRef*[T](x: ptr AbstractAdapterRef[T]):ptr OdbcAdapterRef[T] =
  cast[ptr OdbcAdapterRef[T]](x)


# when isMainModule:
  # dumpAstGen:
  #   # cast[ptr SqliteAdapterRef[T]](self.adapter)
  #   if self.databaseVersion:
  #     result = self.databaseVersion
  #   else:
  #     self.databaseVersion = body
  #     result = self.databaseVersion
 
