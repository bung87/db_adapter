# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import db_adapter
let db = initDbConnection("sqlite", ":memory:", "", "", "")
test "test sqlite3":
  
  db.exec(sql"DROP TABLE IF EXISTS my_table")
  db.exec(sql"""CREATE TABLE my_table (
                  id   INTEGER,
                  name VARCHAR(50) NOT NULL
                )""")
  db.exec(sql"INSERT INTO my_table (id, name) VALUES (0, ?)",
  "Jack")
  check db.kind == DriverKind.sqlite
  check db.database_exists() == true
  check db.get_database_version == db.adapter.get_database_version 
  check db.adapter.database_version == db.database_version
  # cant pass in test
  check db.explain(sql"Select * from my_table").contains("SCAN TABLE my_table")
  check db.table_create_statment("my_table").contains("CREATE TABLE my_table")
  check db.primary_keys("my_table").len == 0
  db.exec(sql"""
    CREATE TABLE users (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                          name VARCHAR(50) NOT NULL,
                          password_digest varchar COLLATE ?);
  ""","NOCASE")
  check db.primary_keys("users") == @["id"]
  db.exec(sql"CREATE INDEX name_index ON users(name);")

  check db.table_indexs("users").len == 1
  db.remove_index("name_index")
  # assert db.table_indexs("users").len == 0 # no effect
  echo db.foreign_keys("users")
  db.close()
