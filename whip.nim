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
  fastReq: TableRef[HttpMethod, TableRef[string, Handler]]

proc send*(my: Wreq, data: JsonNode)  = my.req.send(Http200, $data, JSON_HEADER)

proc send*(my: Wreq, data: string) = my.req.send(Http200, data, TEXT_HEADER) 

proc send*[T](my: Wreq, data: T, headers=TEXT_HEADER) = my.req.send(Http200, $data, headers) 

proc `%`*(t : StringTableRef): JsonNode =
  result = newJObject()
  if t == nil: return
  for i,v in t: result.add(i,%v)

func path*(my: Wreq): string = my.req.path.get

func header*(my: Wreq, key:string): seq[string] = my.req.headers.get().table[key]

func headers*(my: Wreq): TableRef[string, seq[string]] = my.req.headers.get().table

func path*(my: Wreq, key:string): string = my.param[key]

func query*(my: Wreq, key:string): string = my.query[key]

proc body*(my: Wreq): JsonNode = parseJson(my.req.body.get()) ?: JsonNode() 

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

func initWhip*(): Whip = 
  let w = Whip(router: newRouter[Handler](), fastReq: newTable[HttpMethod, TableRef[string, Handler]]())
  for m in @[HttpGet, HttpPut, HttpPost, HttpPatch, HttpDelete]: 
    w.fastReq[m] = newTable[string, Handler]()
  w

proc onReq*(my: Whip, path: string, handle: Handler, meths:seq[HttpMethod]) = 
  for m in meths:
    if path.contains('{'): my.router.map(handle, toLower($m), path)
    else: my.fastReq[m][path] = handle
  
proc onGet*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpGet])

proc onPut*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpPut])

proc onPost*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpPost])

proc onDelete*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpDelete])

proc start*(my: Whip, port:int = 8080) = 
  my.router.compress()
  run(proc (req:Request):Future[void] {.closure,gcsafe.} = 
    let path = req.path.get()
    let meth = req.httpMethod.get()
    let fast = my.fastReq[meth]
    if fast.hasKey(path): fast[path](Wreq(req:req)) 
    else: 
      let route = my.router.route($meth,parseUri(path))
      if route.status != routingSuccess: req.error()
      else: route.handler(Wreq(req:req, query:route.arguments.queryArgs, param:route.arguments.pathArgs))
  , Settings(port:Port(port)))

when isMainModule: import tests