import asyncdispatch, json, strutils, random, strformat, db_postgres

#[
proc init(db:apgConnection)  = 
  let model = readFile("model.sql")
  for m in model.split(';'):
    if m.strip != "": db.exec(sql(m), [])
  db.exec(sql"truncate world")
  let max = 9
  var ins = "insert into world values (1, 10)"
  for i in 2..max: ins &= &",({i}, {rand(100000)})"
  db.exec(sql(ins))
]#

const GET_ONE = sql"select id, randomNumber from world where id = $1"

var db = open("localhost", "mtaylor", "", "empower")

let byId = db.prepare("worldById", GET_ONE, 1)

func `$`(r:Row): string = "{\"id\": " & $r[0] & ",\"randomNumber\": " & $r[1] & "}"

func `$`(r:seq[Row]): string = "[" & r.join(",") & "]"

#[
func `%`(r:Row): JsonNode = 
  var o = newJObject()
  o["id"] = newJInt(r[0])
  o["randomNumber"] = newJInt[1]
  return o
]#

proc worldRaw*():string  = $db.getRow(byId, rand(8)+1)

proc worldRaw*(len:int):string  = 
  var rows: seq[Row]
  for i in 0..len: rows.add(db.getRow(byId, rand(8)+1))
  return $rows

