import ../whip, sugar, algorithm, random, emerald, db_postgres, strutils
{.checks: off, optimization: speed.}

const FORTUNE_ALL = sql"select id, message from fortune"
const WORLD_BY_ID = sql"select id, randomNumber from world where id = $1"

var pool:array[10, DbConn]
var prep:array[10, SqlPrepared]
for i in 0..9: 
  pool[i] = open("localhost", "mtaylor", "", "empower")
  prep[i] = pool[i].prepare("worldById" & $i, WORLD_BY_ID, 1)
  
var i = 0

proc db() : DbConn = 
  if i == 9: i = 0 else: i = i + 1
  return pool[i]
  

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


#let worldById = pool[0].prepare("worldById", WORLD_BY_ID, 1)

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
  
proc fortunes(): string= 
  forTpl.rows = @[@["0", "Additional fortune added at request time"]]
  for r in db().fastRows(FORTUNE_ALL): forTpl.rows.add(r)
  #forTpl.rows = db.getAllRows(FORTUNE_ALL)
  #forTpl.rows.add(@["0", "Additional fortune added at request time"])
  forTpl.rows.sort do (x, y: Row) -> int : cmp(x[1], y[1])
  forTpl.render(stream)
  return stream.data

proc worldRaw():string  = $db().getRow(prep[i], rand(8)+1)

proc worldRaw(len:int):string  = 
  var rows: seq[Row]
  for i in 0..len: rows.add(db().getRow(prep[i], rand(8)+1))
  return $rows

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
