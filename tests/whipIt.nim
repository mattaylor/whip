import ../whip, sugar, asyncdispatch, packedjson, strtabs
{.checks: off, optimization: speed.}

let w = initWhip()

const JSON_DATA = """{"message": "Hello World!"}"""
const TEXT_DATA = "Hello World!"

w.onGet "/json", r => r.json(JSON_DATA)
w.onGet "/text", r => r.send(TEXT_DATA)
w.onGet "/json/{name}", r => r.json(%*{ "hello": r.path("name")})
w.onGet "/text/{name}", r => r.send("hello " & r.path("name"))
w.onGet "/test/{name}", r => r.json(r)
w.onGet "/test", r => r.json(r)

w.start(8080)
