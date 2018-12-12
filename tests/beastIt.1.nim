import options, asyncdispatch, json

import httpbeast

proc onRequest(req: Request): Future[void] =
  if req.httpMethod == some(HttpGet):
    case req.path.get()
    of "/json": req.send(Http200, $(%*{"result": "Hello World!"}))
    of "/text": req.send(Http200, "Hello World!", "Content-Type: text/plain")
    else: req.send(Http404)

run(onRequest)