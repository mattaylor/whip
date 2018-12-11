import whip, sugar, json, strformat, strtabs

let w = initWhip()

w.onGet "/test", (r:Wreq) => r.send(%r)

w.onPost "/test", (r:Wreq) => r.send(%r)

w.onGet "/test/{name}", (w:Wreq) => w.send(%*{ "result": "hello " & w.path("name")})

w.start(8000)
