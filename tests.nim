import whip, coro, sugar, json, strformat,  strutils, httpclient, asyncdispatch, httpcore, unittest

const TEXT_DATA = "hello world"

proc testServe() {.thread.} =
  let w = initWhip()
  w.onPost "/test/{name}", (r:Wreq) => r.send(%r)
  w.onGet "/test", (r:Wreq) => r.send(%r)
  w.onGet "/text", (r:Wreq) => r.send(TEXT_DATA)
  w.onGet "/json", (r:Wreq) => r.send(%*{"result": TEXT_DATA})
  w.onGet "/text/{name}", (w:Wreq) => w.send("hello " & w.path("name"))
  w.onGet "/json/{name}", (w:Wreq) => w.send(%*{ "hello": w.path("name")})
  w.start(8000)

var t: Thread[void]
createThread(t, testServe)

let c = newAsyncHttpClient()
proc runTests() {.async.} = 
  const HOST = "http://localhost:8000"
  suite "GET /text":
    let r = await c.get(HOST & "/text")
    test "status": check(r.status == Http200)
    test "body": check((await r.body) == TEXT_DATA)

  suite "GET /text/{name}":
    let r = await c.get(HOST & "/text/mat")
    test "status": check(r.status == Http200)
    test "body": check((await r.body) == "hello mat")

  suite "GET /json/{name}":
    let r = await c.get(HOST & "/json/whip")
    let b = parseJson(await r.body)
    test "status": check(r.status == Http200)
    test "name": check(b["hello"].getStr() == "whip")

  suite "POST /test/{name}":
    let p = "/test/whip?key1=val1"
    let r = await c.post(HOST & p, $(%*{"hello": "whip"}))
    let b = parseJson(await r.body)
    test "path": check(b["path"].getStr() == p)
    test "body": check(b["body"]["hello"].getStr() == "whip")
    test "param": check(b["param"]["name"].getStr() == "whip")
    test "query": check(b["query"]["key1"].getStr() == "val1")
    test "method": check(b["method"].getStr() == "POST")
  
  suite "GET /test":
    let p = "/test?key1=val1"
    let r = await c.get(HOST & p)
    let b = parseJson(await r.body)
    test "path": check(b["path"].getStr() == p)
    test "query": check(b["query"]["key1"].getStr() == "val1")
    test "method": check(b["method"].getStr() == "GET")
  
waitFor runTests()
