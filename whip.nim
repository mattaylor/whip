import URI, options, critbits, sugar, packedJson, asyncdispatch, httpbeast, nest, tables, httpcore, strutils, strtabs
{.experimental.}

const TEXT_TYPE* = "Content-Type: text/plain"
const JSON_TYPE* = "Content-Type: application/json"

type Wreq* = ref object
  req*: Request
  uri*: URI
  qargs: StringTableRef
  pargs: StringTableRef
  
type Handler* = proc (r: Wreq) {.inline,closure.}

type Whip* = object 
  router: Router[Handler]
  simple: TableRef[HttpMethod, CritBitTree[Handler]]

proc send*[T](my: Wreq, data: T, head=TEXT_TYPE) {.inline,gcsafe.} = my.req.send(Http200, $data, head) 

proc json*(my: Wreq, data: string) {.inline,gcsafe.} =  my.req.send(Http200, data, JSON_TYPE)

proc json*(my: Wreq, data: JsonNode) {.inline,gcsafe.} =  my.req.send(Http200, $data, JSON_TYPE)

proc json*[T](my: Wreq, data: T) {.inline,gcsafe.} =  my.req.send(Http200, $(%data), JSON_TYPE)

func `%`*(t : StringTableRef): JsonNode =
  var o = newJObject()
  if t == nil: return
  for i,v in t: o[i] = newJString(v)
  return o  

proc query*(my: Wreq): StringTableRef = 
  if my.qargs.isNil: my.qargs = newStringTable(my.uri.query.split({'&','='}), modeCaseSensitive)
  return my.qargs
  
func header*(my: Wreq, key:string): seq[string] = my.req.headers.get().table[key]

func headers*(my: Wreq): TableRef[string, seq[string]] = my.req.headers.get().table

func path*(my: Wreq): string = my.req.path.get

func path*(my: Wreq, key:string): string = my.pargs[key]

proc body*(my: Wreq): JsonNode  = 
  if my.req.body.get == "": JsonNode() else: parseJson(my.req.body.get()) 

proc `%`*(my:Wreq): JsonNode = %{
  "path": %my.req.path.get(),
  "body": %my.body(),
  "method": %my.req.httpMethod.get(),
  "query": %my.query(),
  "param": %my.pargs
}

proc error(my:Request, msg:string = "Not Found") = my.send(
  Http400, 
  $(%*{ "message": msg, "path": my.path.get(), "method": my.httpMethod.get()}), 
  JSON_TYPE
)

func initWhip*(): Whip {.inline.} = 
  let w = Whip(router: newRouter[Handler](), simple: newTable[HttpMethod, CritBitTree[Handler]]())
  for m in @[HttpGet, HttpPut, HttpPost, HttpPatch, HttpDelete]: 
    w.simple[m] =  CritBitTree[Handler]()
  return w

proc onReq*(my: Whip, path: string, handle: Handler, meths:seq[HttpMethod]) = 
  for meth in meths:
    if path.contains('{'): my.router.map(handle, toLower($meth), path)
    else: my.simple[meth][path] = handle
  
proc onGet*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpGet])

proc onPut*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpPut])

proc onPost*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpPost])

proc onDelete*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpDelete])

proc start*(my: Whip, port:int = 8080) = 
  my.router.compress()
  run(proc (beast:Request):Future[void] {.inline,closure,gcsafe.} = 
    var sim = my.simple[beast.httpMethod.get()]
    var req = Wreq(req:beast, uri:parseUri(beast.path.get()))
    if sim.hasKey(req.uri.path): sim[req.uri.path](req)
    else:
      let route = my.router.route($beast.httpMethod.get(),req.uri)
      if route.status != routingSuccess: beast.error()
      else: 
        req.qargs = route.arguments.queryArgs
        req.pargs = route.arguments.pathArgs
        route.handler(req)
        sim[req.uri.path] = func(r:Wreq) {.inline,closure.} = 
          r.pargs = route.arguments.pathArgs
          route.handler(r)
   , Settings(port:Port(port)))
  echo "started"

when isMainModule: import tests/whiptest