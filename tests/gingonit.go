package main

import "github.com/gin-gonic/gin"

func main() {
	gin.SetMode(gin.ReleaseMode)
	r := gin.Default()
	r.GET("/json", func(c *gin.Context) {c.JSON(200, gin.H{"result": "hello world"})})
	r.GET("/json/:name", func(c *gin.Context) {c.JSON(200, gin.H{"hello": c.Param("name")})})
	r.GET("/text", func(c *gin.Context) {c.String(200, "hello world")})
	r.GET("/text/:name", func(c *gin.Context) {c.String(200, "hello " + c.Param("name"))})
	r.Run() // listen and serve on 0.0.0.0:8080
}
