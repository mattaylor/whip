import ../whip, sugar, fortunes, worldOrm, worldRaw, strutils
{.checks: off, optimization: speed.}

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
