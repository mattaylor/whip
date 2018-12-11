import ../whip, sugar, json

let w = initWhip()

#w.onGet "/test", (r:Wreq) => r.send(%r)
const JSON_DATA = $(%*{"result": "hello world"})
const TEXT_DATA = "Hello World"

w.onGet "/text", (r:Wreq) => r.send(TEXT_DATA)
w.onGet "/json", (r:Wreq) => r.send(JSON_DATA)
w.onGet "/json/{name}", (r:Wreq) => r.send(%*{ "hello": r.path("name")})
w.onGet "/text/{name}", (r:Wreq) => r.send("hello " & r.path("name"))

w.start(8000)
