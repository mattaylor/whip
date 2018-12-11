import asyncdispatch, URI, options, json, httpbeast, nest, elvis, httpcore, tables, strutils, strtabs

const JSON_HEADER = "Content-Type: text/plain"
const TEXT_HEADER = "Content-Type: application/json"

type Opts = object
  port*: Port
  bindAddr*: string

type Wreq* = object
  req: Request
  query*: StringTableRef
  param*: StringTableRef
  
type Handler = proc (r: Wreq) {.gcsafe.}

type Whip = object 
  router: Router[Handler]
  fastGet: TableRef[string, Handler]
  fastPut: TableRef[string, Handler]

proc send*(my: Wreq, data: JsonNode)  = my.req.send(Http200, $data, JSON_HEADER)

proc send*[T](my: Wreq, data: T) = my.req.send(Http200, $data, TEXT_HEADER) 

proc `%`*(t : StringTableRef): JsonNode =
  result = newJObject()
  if t == nil: return
  for i,v in t: result.add(i,%v)

proc path*(my: Wreq): string = my.req.path.get

proc header*(my: Wreq, key:string): seq[string] = my.req.headers.get().table[key]

proc headers*(my: Wreq): TableRef[string, seq[string]] = my.req.headers.get().table

proc path*(my: Wreq, key:string): string = my.param[key]

proc query*(my: Wreq, key:string): string = my.query[key]

proc body*(my: Wreq): JsonNode = parseJson(my.req.body.get()) ?: JsonNode() 

#proc json*(my: Wreq): JsonNode = parseJson(my.req.body.get() ?: "")

#proc text*(my: Wreq): string = my.req.body.get() ?: ""

proc `%`*(my:Wreq): JsonNode = %*{
  "path": my.req.path.get(),
  "body": my.body(),
  "method": my.req.httpMethod.get(),
  "query": my.query,
  "param": my.param
}

proc error(my:Request, msg:string = "Not Found") = my.send(
  Http400, 
  $(%*{ "message": msg, "path": my.path.get(), "method": my.httpMethod.get()}), 
  JSON_HEADER
)

proc initWhip*(): Whip = Whip(
  router: newRouter[Handler](), 
  fastGet: newTable[string, Handler](),
  fastPut: newTable[string, Handler]()
)

proc onGet*(my: Whip, path: string, h: Handler) = 
  if path.contains('{'): my.router.map(h, $GET, path)
  else: my.fastGet[path] = h

proc onPut*(my: Whip, path: string, h: Handler) = my.router.map(h, $PUT, path)

proc onPost*(my: Whip, path: string, h: Handler) = my.router.map(h, $POST, path)

proc onDelete*(my: Whip, path: string, h: Handler) = my.router.map(h, $DELETE, path)

proc fastRoutes*(my: Whip, meth: HttpMethod): TableRef[string, Handler] =
  case meth
  of HttpGet: my.fastGet
  of HttpPut: my.fastPut
  else: raise newException(Exception, "Invalid Method")

proc start*(my: Whip, port:int = 8080) = 
  my.router.compress()
  run(proc (req:Request):Future[void] {.closure.} = 
    let path = req.path.get()
    let meth = req.httpMethod.get()
    let fast = my.fastRoutes(meth)
    #if fast.len > 0 and fast.hasKey(path): fast[path](Wreq(req:req)) 
    if fast.hasKey(path): fast[path](Wreq(req:req)) 
    else: 
      let route = my.router.route($meth,parseUri(path))
      if route.status != routingSuccess: req.error()
      else: route.handler(Wreq(req:req, query:route.arguments.queryArgs, param:route.arguments.pathArgs))
  , Settings(port:Port(port)))

when isMainModule: import tests