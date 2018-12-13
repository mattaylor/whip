import options, asyncdispatch, json, httpbeast
{.checks: off, optimization: speed.}

proc onRequest(req: Request): Future[void] =
  if req.httpMethod == some(HttpGet):
    case req.path.get()
    of "/json":
      const data = $(%*{"message": "Hello World!"})
      const headers = "Content-Type: application/json"
      req.send(Http200, data, headers)
    of "/text":
      const data = "Hello World!"
      const headers = "Content-Type: text/plain"
      req.send(Http200, data, headers)
    else: req.send(Http404)

run(onRequest)