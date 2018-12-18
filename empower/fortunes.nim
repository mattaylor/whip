import emerald, algorithm, db_postgres

const GET_ALL = sql"select id, message from fortune"

var db = open("localhost", "mtaylor", "", "empower")

#let getAll = db.prepare("worldAll", GET_ALL)

proc temp (rows: seq[seq[string]]) {.html_templ.} =
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

var stream = newStringStream()
var temp = newTemp()

proc fortunes*(): string= 
  temp.rows = @[]
  for r in db.fastRows(GET_ALL): temp.rows.add(r)
  temp.rows.add(@["0", "Additional fortune added at request time"])
  temp.rows.sort do (x, y: Row) -> int : cmp(x[1], y[1])
  temp.render(stream)
  return stream.data
