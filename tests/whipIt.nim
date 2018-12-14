import ../whip, sugar, packedjson, strtabs
{.checks: off, optimization: speed.}

let w = initWhip()

const JSON_DATA = """{"message": "Hello World!"}"""
const TEXT_DATA = "Hello World!"

w.onGet "/json", (r:Wreq) => r.json(JSON_DATA)
w.onGet "/text", (r:Wreq) => r.send(TEXT_DATA)
w.onGet "/json/{name}", (r:Wreq) => r.json(%*{ "hello": r.path("name")})
w.onGet "/text/{name}", (r:Wreq) => r.send("hello " & r.path("name"))
w.onGet "/test/{name}", (r:Wreq) => r.json(r)
w.onGet "/test", (r:Wreq) => r.json(r)

w.start(8080)
