package main

import (
	"fmt"
	"log"
	"github.com/buaazp/fasthttprouter"
	"github.com/valyala/fasthttp"
)

func Hello1(ctx *fasthttp.RequestCtx) {
	fmt.Fprint(ctx, "Hello World!\n")
}

func Hello2(ctx *fasthttp.RequestCtx) {
	fmt.Fprintf(ctx, "hello, %s!\n", ctx.UserValue("name"))
}

func main() {
	router := fasthttprouter.New()
	router.GET("/text", Hello1)
	router.GET("/text/:name", Hello2)
	log.Fatal(fasthttp.ListenAndServe(":8080", router.Handler))
}