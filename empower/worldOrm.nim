import strutils, random, strformat
import ../../nim-orm/orm_postgres

type World = object of Model
  id: int
  randomNumber: int

proc init()  = 
  let setup = readFile("model.sql")
  for s in setup.split(';'):
    if s.strip != "": Model.exec(s, [])
  Model.exec("truncate world",[])
  let max = 9
  var ins = "insert into world values (1, 10)"
  for i in 2..max: ins &= &",({i}, {rand(100000)})"
  Model.exec(ins)

Model.open("localhost", "mtaylor","", "empower")

#init()
#for w in World.fetch("SELECT `randomNumber` from world limit 1"):
#for w in World: echo $w.randomNumber

proc worldOrm*() : string = 
  for w in World.fetch("SELECT randomNumber from world limit 1"): 
    return "{\"id\": " & $w.id & ",\"randomNumber\": " & $w.randomNumber & "}"