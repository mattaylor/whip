import mofuw, json
{.checks: off, optimization: speed.}

const JSON_DATA = $(%*{"message": "Hello World!"})
const TEXT_DATA = "Hello World!"
const JSON_TYPE = "application/json"
const TEXT_TYPE = "text/plain"

routes:
  get "/text": mofuwResp(HTTP200, TEXT_TYPE, TEXT_DATA)
  get "/json": mofuwResp(HTTP200, JSON_TYPE, JSON_DATA)
  get "/text/{name}": mofuwResp(HTTP200, TEXT_TYPE, "Hello" & ctx.params("name"))
  get "/json/{name}": mofuwResp(HTTP200, JSON_TYPE, $(%{"Hello": %ctx.params("name")}))
  
newServeCtx(port = 8080, handler = mofuwHandler).serve()