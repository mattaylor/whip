import ../whip, sugar, templates, asyncdispatch, asyncpg, algorithm, random, db_postgres, strutils
{.checks: off, optimization: speed.}

var sdb = open("localhost", "mtaylor", "", "empower")
var adb = newPool()

waitFor adb.connect("host=localhost user=mtaylor dbname=empower")

const FORTUNE_ALL = sql"select id, message from fortune"
const WORLD_BY_ID = "select id, randomNumber from world where id ="

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

let worldById = sdb.prepare("worldById", sql(WORLD_BY_ID & "$1"), 1)

func `$`(r:seq[string]): string = "{\"id\": " & $r[0] & ",\"randomNumber\": " & $r[1] & "}"

#func `$`(r:seq[Row]): string = "[" & r.join(",") & "]"

proc fortemp (rows:seq[seq[string]]): string = tmpli html"""
  <html>
    <head><title>Fortunes</title></head>
    <body>
      <table>
        <tr><th>Id</th><th>Message</th></tr>
        $for r in rows {
          <tr><td>$(r[0])</td><td>$(r[1])</td></tr>
        }
      </table>
    </body>
  </html>
  """
  
proc fortunes(): string= 
  var rows = @[@["0", "Additional fortune added at request time"]]
  for r in sdb.fastRows(FORTUNE_ALL): rows.add(r)
  rows.sort do (x, y: seq[string]) -> int : cmp(x[1], y[1])
  fortemp(rows)
  
proc worldRaw():string  = $sdb.getRow(worldById, rand(8)+1)

proc worldRaw(len:int):string  = 
  var sql = ""
  var txt = "["
  for i in 0..len: sql &= WORLD_BY_ID & $(rand(8)+1) & ";"
  let res = waitFor adb.exec(sql)
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

w.start(8080)
