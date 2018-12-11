import ../whip, sugar, json

let w = initWhip()

#w.onGet "/test", (r:Wreq) => r.send(%r)
w.onGet "/text", (r:Wreq) => r.send("hello world")
w.onGet "/json", (r:Wreq) => r.send(%{"result": %"hello world"})
w.onGet "/json/{name}", (w:Wreq) => w.send(%*{ "result": "hello " & w.path("name")})
w.onGet "/text/{name}", (w:Wreq) => w.send("hello " & w.path("name"))

w.start(8000)
