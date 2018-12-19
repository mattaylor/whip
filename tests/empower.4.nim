func isNil(s:string): bool =  (s != "")

import ../whip, asyncdispatch, sugar, algorithm, random, emerald, asyncpg, strutils
{.checks: off, optimization: speed.}


var db = newPool()
waitFor db.connect("host=localhost user=mtaylor dbname=empower")

const FORTUNE_ALL = "select id, message from fortune"
const WORLD_BY_ID = "select id, randomNumber from world where id = "

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


#let worldById = db.prepare("worldById", WORLD_BY_ID, 1)

func `$`(r:Row): string = "{\"id\": " & $r[0] & ",\"randomNumber\": " & $r[1] & "}"

func `$`(r:seq[Row]): string = "[" & r.join(",") & "]"

proc fortuneTpl (rows: seq[seq[string]]) {.html_templ.} =
 html(lang="en"):
  head: 
    title: "Fortunes"
  body:
    table:
      tr:
        th: "Id"
        th: "Message"
      for r in rows:
        tr:
          td: put r[0]
          td: put r[1]

let stream = newStringStream()
let forTpl = newFortuneTpl()
  
proc fortunes(): string  = 
  let res =  waitFor db.exec(FORTUNE_ALL)
  forTpl.rows = res[0].getAllRows()
  forTpl.rows.add(@["0", "Additional fortune added at request time"])
  forTpl.rows.sort do (x, y: Row) -> int : cmp(x[1], y[1])
  forTpl.render(stream)
  return stream.data

proc worldRaw():string  = 
  $((waitFor db.exec(WORLD_BY_ID & $(rand(8)+1)))[0].getRow())

proc worldRaw(len:int):string  = 
  var sql = ""
  var txt = "["
  for i in 0..len: sql &= WORLD_BY_ID & $(rand(8)+1) & ";"
  let res = waitFor db.exec(sql)
  for i in 0..len: txt &= $res[i].getRow() & ","
  return txt & "]"

let w = initWhip()

const JSON_DATA = """{"message": "Hello World!"}"""
const TEXT_DATA = "Hello World!"

w.onGet "/json", (r:Wreq) => r.json(JSON_DATA)
w.onGet "/plaintext", (r:Wreq) => r.send(TEXT_DATA)
w.onGet "/fortunes",  (r:Wreq) => r.html(fortunes())
w.onGet "/db",  (r:Wreq) => r.json(worldRaw())
w.onGet "/queries",(r:Wreq) => r.json(worldRaw(parseInt(r.query("queries"))))
#w.onGet "/dbOrm",  (r:Wreq) => r.json(worldOrm())

w.start(8080)
