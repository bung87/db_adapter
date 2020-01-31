# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import strutils
import db_adapter
let db = initDbConnection("sqlite", ":memory:", "", "", "")
test "test sqlite3":
  
  db.exec(sql"DROP TABLE IF EXISTS myTable")
  db.exec(sql"""CREATE TABLE myTable (
                  id   INTEGER,
                  name VARCHAR(50) NOT NULL
                )""")
  db.exec(sql"INSERT INTO myTable (id, name) VALUES (0, ?)",
  "Jack")
  check db.kind == DriverKind.sqlite
  check db.databaseExists() == true
  check db.getDatabaseVersion == db.adapter.getDatabaseVersion 
  check db.adapter.databaseVersion == db.databaseVersion
  check db.explain(sql"Select * from myTable").contains("SCAN TABLE myTable")
  check db.tableCreateStatment("myTable").contains("CREATE TABLE myTable")
  check db.primaryKeys("myTable").len == 0
  db.exec(sql"""
    CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                          name VARCHAR(50) NOT NULL,
                          passwordDigest varchar COLLATE ?);
  ""","NOCASE")
  check db.primaryKeys("users") == @["id"]
  db.exec(sql"CREATE INDEX nameIndex ON users(name);")

  check db.tableIndexs("users").len == 1
  db.removeIndex("nameIndex")
  # assert db.tableIndexs("users").len == 0 # no effect
  echo db.foreignKeys("users")
  db.close()
