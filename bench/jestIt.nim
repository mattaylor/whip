import jester, json, asyncdispatch

routes:
  get "/text": resp "Hello world"
  get "/json": resp %*{"result": %"Hello World"}
  get "/text/@name": resp "Hello " & @"name"
  get "/json/@name": resp %*{"result": "Hello " & @"name"}
  #[
else:
  proc match(request: Request): Future[ResponseData] {.async.} =
    case request.path
    of "/":
      result = (TCActionSend, Http200, {:}.newHttpHeaders, "Hello World!", true)
    else:
      result = (TCActionSend, Http404, {:}.newHttpHeaders, "Y'all got lost", true)
  var j = initJester(match)
  j.serve()
]#
runForever()