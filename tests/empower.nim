import ../whip, sugar, packedjson, templates, strformat, asyncdispatch, asyncpg, algorithm, random, db_postgres, strutils
{.checks: off, optimization: speed.}

var sdb = open("localhost", "mtaylor", "", "empower")
var adb = newPool()

waitFor adb.connect("host=localhost user=mtaylor dbname=empower")

const GET_FORTUNE_ALL = sql"select id, message from fortune"
const GET_WORLD_BY_ID = "select id, randomNumber from world where id ="

proc init(db:DbConn)  = 
  let model = readFile("empower.sql")
  for m in model.split(';'): 
    if m.strip != "": db.exec(sql(m), [])
  var in1 = "insert into world values "
  for i in 0..1000: in1 &= &"({i}, {rand(100000)}),"
  db.exec sql(in1.strip(chars={','}))
  var in2 = "insert into fortune values "
  for i in 1..12: in2 &= &"({i}, 'A fortune {rand(100)}'),"
  db.exec sql(in2.strip(chars={','}))

let worldById = sdb.prepare("worldById", sql(GET_WORLD_BY_ID & "$1"), 1)

func `$`(r:seq[string]): string = "{\"id\": " & $r[0] & ",\"randomNumber\": " & $r[1] & "}"

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
  for r in sdb.fastRows(GET_FORTUNE_ALL): rows.add(r)
  rows.sort do (x, y: seq[string]) -> int : cmp(x[1], y[1])
  fortemp(rows)
  
proc getWorld(q:string):Future[apgResult] = 
  var len = if not(q.isDigit()): 1 else: parseInt(q)
  if len < 1: len = 1 elif len > 500: len = 500
  var sql = ""
  for i in 1..len: sql &= GET_WORLD_BY_ID & $rand(1000) & ";"
  adb.exec(sql)

proc queries(q:string): Future[string] {.async.} =
  let res = await getWorld(q)
  var txt = "[" & $res[0].getRow()
  for i in 1..(res.len - 1): txt &= "," & $res[i].getRow()
  return txt & "]"

proc updates(q:string):Future[string] {.async.} =
  let res = await getWorld(q)
  var txt, sql = "["
  for i in 0..(res.len - 1): 
    var row = res[i].getRow()
    row[1] = $rand(1000)
    sql &= ";update world set randomNumber=" & row[1] & " where id=" & row[0]
    txt &= $row & ","
  txt[txt.len-1] = ']' 
  sql[0] = ' '
  discard(await adb.exec(sql))
  return txt

#sdb.init()

let w = initWhip()

const TEXT_DATA = "Hello World!"
let JSON_DATA = %*{"message": "Hello World!"}

w.onGet "/json", (r:Wreq) => r.json(JSON_DATA)
w.onGet "/plaintext", (r:Wreq) => r.send(TEXT_DATA)
w.onGet "/fortunes",  (r:Wreq) => r.html(fortunes())
w.onGet "/db",  (r:Wreq) => r.json($sdb.getRow(worldById, rand(1000)))
w.onGet "/queries",  (r:Wreq) => r.json(queries(r.query("queries")))
w.onGet "/updates", (r:Wreq) => r.json(updates(r.query("queries")))

w.start(8080)
