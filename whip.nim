import URI, options, json, asyncdispatch, httpbeast, nest, httpcore, tables, strutils, strtabs

const TEXT_HEADER* = "Content-Type: text/plain"
const JSON_HEADER* = "Content-Type: application/json"

type Wreq* = object
  req: Request
  query*: StringTableRef
  param*: StringTableRef
  
type Handler = proc (r: Wreq) {.gcsafe.}

type Whip = object 
  router: Router[Handler]
  simple: TableRef[HttpMethod, TableRef[string, Handler]]
  docDir: string
  binDir: string


proc send*(my: Wreq, data: JsonNode)  = my.req.send(Http200, $data, JSON_HEADER)

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

proc body*(my: Wreq): JsonNode = 
  if my.req.body.get == "": JsonNode() else: parseJson(my.req.body.get()) 

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

func parseQuery*(query: string): StringTableRef = 
  newStringTable(query.split({'&','='}), modeCaseSensitive)

func initWhip*(): Whip = 
  let w = Whip(router: newRouter[Handler](), fastReq: newTable[HttpMethod, TableRef[string, Handler]]())
  for m in @[HttpGet, HttpPut, HttpPost, HttpPatch, HttpDelete]: 
    w.simple[m] = newTable[string, Handler]()
  w

proc onReq*(my: Whip, path: string, handle: Handler, meths:seq[HttpMethod]) = 
  for meth in meths:
    if path.contains('{'): my.router.map(handle, toLower($meth), path)
    else: my.faster[meth][path] = handle
  
proc onGet*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpGet])

proc onPut*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpPut])

proc onPost*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpPost])

proc onDelete*(my: Whip, path: string, h: Handler) = my.onReq(path, h, @[HttpDelete])

proc start*(my: Whip, port:int = 8080) = 
  my.router.compress()
  run(proc (req:Request):Future[void] {.closure,gcsafe.} = 
    let sim = my.simple[req.httpMethod.get()]
    let uri = parseUri(req.path.get())
    if sim.hasKey(uri.path): sim[uri.path](Wreq(req:req, query:parseQuery(uri.query)))
    else: 
      let route = my.router.route($req.httpMethod.get(),uri)
      if route.status != routingSuccess: req.error()
      else: route.handler(Wreq(req:req, query:route.arguments.queryArgs, param:route.arguments.pathArgs))
  , Settings(port:Port(port)))
  echo "started"

when isMainModule: import tests/whiptest