import ../whip, sugar, json
{.checks: off, optimization: speed.}

let w = initWhip()

const JSON_DATA = $(%*{"result": "hello world"})
const TEXT_DATA = "Hello World"

w.onGet "/text", (r:Wreq) => r.send(TEXT_DATA, TEXT_HEADER)
w.onGet "/json", (r:Wreq) => r.send(JSON_DATA, JSON_HEADER)
w.onGet "/json/{name}", (r:Wreq) => r.send(%*{ "hello": r.path("name")})
w.onGet "/text/{name}", (r:Wreq) => r.send("hello " & r.path("name"))
w.onGet "/test/{name}", (r:Wreq) => r.send(%r)
w.onGet "/test", (r:Wreq) => r.send(%r)

w.start(8000)
