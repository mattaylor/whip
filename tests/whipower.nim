import ../whip, sugar, packedjson, templates, uri, strformat, asyncdispatch, ../../asyncpg/asyncpg, algorithm, random, strutils
{.checks: off, optimization: speed.}

var db = newPool(10)

let msgs = @[
  """<script>alert("This should not be displayed in a browser alert box");</script>""",
  "A bad random number generator: 1, 1, 1, 1, 1, 4.33e+67, 1, 1, 1",
  "A computer program does what you tell it to do, not what you want it to do.",
  "A computer scientist is someone who fixes things that aren't broken.",
  "A list is only as strong as its weakest link. — Donald Knuth",
  "After enough decimal places, nobody gives a damn.",
  "Any program that runs right is obsolete.",
  "Computers make very fast, very accurate mistakes.",
  "Emacs is a nice operating system, but I prefer UNIX. — Tom Christaensen",
  "Feature: A bug with seniority.",
  "fortune: No such file or directory",
  "フレームワークのベンチマーク"
]

func sanitize(s:string): string =
  var r = ""
  for c in s:
    case c:
    of '&': r &= "&amp;"
    of '<': r &= "&lt;"
    of '>': r &= "&gt;"
    of '"': r &= "&quot"
    of '\'': r &= "&#39;"
    of '-': r &= "-"
    else: r &= c
  return r
  
proc init(db:apgPool) {.async.} =
  var sql = readFile("empower.sql").split(';')
  var in1 = "insert into world values "
  for i in 0..10000: in1 &= &"({i}, {rand(100000)}),"
  sql.add(in1.strip(chars={','}))
  var in2 = "insert into fortune values "
  for i,m in msgs: in2 &= "(" & $(i+1) & ", E" & m.escape("'", "'") & "),"
  sql.add(in2.strip(chars={','}))
  asyncCheck db.exec(sql.join(";"))
  
func `$`(r:seq[string]): string = "{\"id\": " & $r[0] & ",\"randomNumber\": " & $r[1] & "}"

func fortemp (rows:seq[seq[string]]): string = tmpli html"""
  <html>
    <head><title>Fortunes</title></head>
    <body>
      <table>
        <tr><th>Id</th><th>Message</th></tr>
        $for r in rows {
          <tr><td>$(r[0])</td><td>$(sanitize(r[1]))</td></tr>
        }
      </table>
    </body>
  </html>
  """

proc fortunes(): Future[string] {.async.} = 
  var res = await db.exec("select id, message from fortune")
  var rows = res[0].getRows(12)
  rows.add @["0", "Additional fortune added at request time"]
  rows.sort do (x, y: seq[string]) -> int : cmp(x[1], y[1])
  return fortemp(rows)

proc getWorld(q:string):Future[apgResult] = 
  var len = parseInt(q)
  if len < 1: len = 1 elif len > 500: len = 500
  var sql = ""
  for i in 1..len: sql &= "EXECUTE getWorldById(" & $rand(1000) & ");"
  db.exec(sql)

proc single(): Future[string] {.async.} = 
  return $((await db.exec("EXECUTE getWorldById(" & $rand(1000) & ")"))[0].getRow())

proc queries(q:string): Future[string] {.async.} =
  let res = await getWorld(q)
  var txt = "[" & $res[0].getRow()
  for i in 1..(res.len - 1): txt &= "," & $res[i].getRow()
  return txt & "]"

proc updates(q:string):Future[string] {.async.} =
  let res = await getWorld(q)
  var rows = newSeq[seq[string]](res.len)
  for i in 0..(res.len-1): rows[i] = @[res[i].getRow()[0], $rand(1000)]
  var txt, sql = "["
  #echo rows
  rows.sort do (x, y: seq[string]) -> int : cmp(x[0], y[0])
  for row in rows:
    sql &= ";EXECUTE setWorldById(" & row[1] & "," & row[0] & ")"
    txt &= $row & ","
  txt[txt.len-1] = ']' 
  sql[0] = ' '
  asyncCheck db.exec(sql)
  return txt

waitFor db.connect("host=localhost user=mtaylor dbname=empower")

for i in 0..9: discard db.exec """
    PREPARE getWorldById (int) AS select id, randomNumber from world where id = $1; 
    PREPARE setWorldById (int, int) AS update world set randomNumber = $1 where id = $2
  """
#  PREPARE getFortunes  () AS select id, message from fortune

waitFor db.init()

let w = initWhip()

const TEXT_DATA = "Hello World!"
const JSON_DATA = """{"message": "Hello World!"}"""
#let JSON_DATA = %{"message": %"Hello World!"}

w.onGet "/json", r => r.json(JSON_DATA)
w.onGet "/plaintext", r => r.send(TEXT_DATA)
w.onGet "/fortune",  r => r.html(fortunes())
w.onGet "/db",  r => r.json(single())
w.onGet "/queries",  r => r.json(queries(r.query("queries")))
w.onGet "/update", r => r.json(updates(r.query("queries")))

w.start(8080)
