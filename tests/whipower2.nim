import ../whip, sugar, pg, packedjson, templates, strformat, asyncdispatch, algorithm, random, strutils
{.checks: off, optimization: speed.}

#var sdb = open("localhost", "mtaylor", "", "empower")
#var adb = newPool()
let db = newAsyncPool("localhost", "mtaylor", "", "empower", 40)
#waitFor adb.connect("host=localhost user=mtaylor dbname=empower")

const GET_FORTUNE_ALL = sql"select id, message from fortune"
const GET_WORLD_BY_ID = sql"select id, randomNumber from world where id = ?"
const SET_WORLD_BY_ID = sql"update world set randomNumber = ? where id = ?"

proc init(db:DbConn)  = 
  let model = readFile("empower.sql")
  for m in model.split(';'): 
    if m.strip != "": db.exec(sql(m), [])
  var in1 = "insert into world values "
  for i in 0..10000: in1 &= &"({i}, {rand(100000)}),"
  db.exec sql(in1.strip(chars={','}))
  var in2 = "insert into fortune values "
  for i in 1..12: in2 &= &"({i}, 'A fortune {rand(100)}'),"
  db.exec sql(in2.strip(chars={','}))

#let worldById = sdb.prepare("worldById", sql(GET_WORLD_BY_ID & "$1"), 1)

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
  
proc fortunes(): Future[string] {.async.} = 
  var rows = await db.rows(GET_FORTUNE_ALL, @[])
  rows.add @["0", "Additional fortune added at request time"]
  rows.sort do (x, y: seq[string]) -> int : cmp(x[1], y[1])
  return fortemp(rows)
  
proc getWorld(q:string):seq[Future[seq[Row]]] = 
  var len = parseInt(q)
  if len < 1: len = 1 elif len > 500: len = 500
  var res = newSeq[Future[seq[Row]]]()
  for i in 1..len: res.add db.rows(GET_WORLD_BY_ID, @[$rand(1000)])
  return res

proc queries(q:string): string =
  var txt = "[" 
  for r in getWorld(q): txt &= $(waitFor r)[0] & ","
  txt[txt.len-1] = ']'
  return txt
  
#[
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
  discard adb.exec(sql)
  return txt
]#

#db.init()

let w = initWhip()

const TEXT_DATA = "Hello World!"
let JSON_DATA = %*{"message": "Hello World!"}

w.onGet "/json", (r:Wreq) => r.json(JSON_DATA)
w.onGet "/plaintext", (r:Wreq) => r.send(TEXT_DATA)
w.onGet "/fortune",  (r:Wreq) => r.send(fortunes(), HTML_TYPE)
#w.onGet "/db",  (r:Wreq) => r.json(
#  $(db.rows(GET_WORLD_BY_ID, @[$rand(1000)]))[0]
#)
w.onGet "/queries",  (r:Wreq) => r.json(queries(r.query("queries")))
#w.onGet "/update", (r:Wreq) => r.json(updates(r.query("queries")))

w.start(8080)
