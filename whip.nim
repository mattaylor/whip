import URI, options, critbits, packedJson, asyncdispatch, httpbeast, nest, tables, httpcore, strutils, strtabs

const TEXT_TYPE* = "Content-Type: text/plain"
const JSON_TYPE* = "Content-Type: application/json"
const HTML_TYPE* = "Content-Type: text/html"

type Wreq* = ref object
  req*: Request
  uri*: URI
  args: RoutingArgs

type Handler* = func (r: Wreq):Future[void] {.inline,closure.}

type Whip* = object 
  router: Router[Handler]
  simple: TableRef[HttpMethod, CritBitTree[Handler]]

proc send*[T](my: Wreq, body: T, head=TEXT_TYPE) {.async,inline,gcsafe.} = my.req.send(Http200, $body, head) 

proc send*[T](my: Wreq, body: Future[T], head=TEXT_TYPE) {.async,inline,gcsafe.} = asyncCheck my.send(await(body), head) 

proc html*(my: Wreq, body: string) {.async,inline,gcsafe.} =  my.req.send(Http200, body, HTML_TYPE)

proc html*(my: Wreq, body: Future[string]) {.async,inline,gcsafe.} =  my.req.send(Http200, await(body), HTML_TYPE)

proc json*(my: Wreq, body: JsonNode) {.async,inline,gcsafe.} =  my.req.send(Http200, $body, JSON_TYPE)

proc json*(my: Wreq, body: string) {.async,inline,gcsafe.} =  my.req.send(Http200, body, JSON_TYPE)

proc json*(my: Wreq, body: Future[string]) {.async,inline,gcsafe.} = my.req.send(Http200, await(body), JSON_TYPE)

proc json*[T](my: Wreq, body: T) {.async,inline,gcsafe.} =  my.req.send(Http200, $(%body), JSON_TYPE)


func `%`*(t : StringTableRef): JsonNode =
  var o = newJObject()
  if t == nil: return
  for i,v in t: o[i] = newJString(v)
  return o  

func query*(my: Wreq): StringTableRef {.inline.} = 
  if my.args.queryArgs.isNil: 
    my.args.queryArgs = newStringTable(my.uri.query.split({'&','='}), modeCaseSensitive)
  my.args.queryArgs

func query*(my: Wreq, key:string): string {.inline.} = 
  if my.args.queryArgs.isNil: 
    my.args.queryArgs = newStringTable(my.uri.query.split({'&','='}), modeCaseSensitive)
  if my.args.queryArgs.hasKey(key): my.args.queryArgs[key] else: ""

func header*(my: Wreq, key:string): seq[string] = my.req.headers.get().table[key]

func headers*(my: Wreq): TableRef[string, seq[string]] = my.req.headers.get().table

func path*(my: Wreq): string = my.req.path.get

func path*(my: Wreq, key:string): string = my.args.pathArgs[key]

proc body*(my: Wreq): JsonNode  = 
  if my.req.body.get == "": JsonNode() else: parseJson(my.req.body.get()) 

proc `%`*(my:Wreq): JsonNode = %{
  "path": %my.req.path.get(), 
  "body": %my.body(), 
  "method": %my.req.httpMethod.get(),
  "query": %my.query(), 
  "param": %my.args.pathArgs
}

proc error(my:Request, msg:string = "Not Found") {.async.} = my.send(
  Http400, 
  $(%*{ "message": msg, "path": my.path.get(), "method": my.httpMethod.get()}), 
  JSON_TYPE
)

func initWhip*(): Whip {.inline.} = 
  let w = Whip(router: newRouter[Handler](), simple: newTable[HttpMethod, CritBitTree[Handler]]())
  for m in HttpMethod: w.simple[m] = CritBitTree[Handler]()
  return w

proc onReq*(my: Whip, path: string, handle: Handler, meths:seq[HttpMethod]) = 
  for meth in meths:
    if path.contains('{'): my.router.map(handle, toLower($meth), path)
    else: my.simple[meth][path] = handle
  
proc onGet*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpGet])

proc onPut*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpPut])

proc onPost*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpPost])

proc onDelete*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpDelete])

func initWreq(req:Request): Wreq {.inline.} =
  var w = Wreq(req:req)
  var b = true
  for v in req.path.get().split('?'):
    if b: w.uri.path = v else: w.uri.query = v
    b = false
  return w

proc start*(my: Whip, port:int = 8080) = 
  my.router.compress()
  run(proc (beast:Request):Future[void]  = 
    var sim = my.simple[beast.httpMethod.get()]
    var req = initWreq(beast)
    if sim.hasKey(req.uri.path): return sim[req.uri.path](req)
    let route = my.router.route($beast.httpMethod.get(),req.uri)
    if route.status != routingSuccess: return beast.error()
    req.args =  route.arguments
    sim[req.uri.path] = func(r:Wreq):Future[void] {.inline,closure.} = 
      r.args.pathArgs = route.arguments.pathArgs
      route.handler(r)
    return route.handler(req)
    
  , Settings(port:Port(port)))
  echo "started"

when isMainModule: import tests/whiptest