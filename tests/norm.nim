import typetraits, typeinfo, strformat

type Norm = ref object of RootObj
  id: int

func byId(My: typedesc, id:int): string = 
  &"select * from {My} where id = {id}"

#func load(My: typedesc, row: seq[string]): My = 
#  My()

proc create(My: typedesc): string = 
  var sql = &"create table {My} ("
  var m:My = new(My)
  m.id = 1
  #for name, value in type(m)().fieldPairs:
  for name, value in m.fieldPairs:
    echo name, value
    #sql &= name & " " & (type value) & ","   
  sql &= ");"
  return sql


type User = ref object of Norm
  name: string

echo User.create()

echo User.byId(12)

