
init = function(args)
  depth = tonumber(args[1]) or 1
  local r = {}
  for i=1,depth do
    r[i] = wrk.format() 
  end
  req = table.concat(r)
end

request = function()
  return req
end

-- wrk -s pipeline.lua http://localhost:8080/text -- 80

