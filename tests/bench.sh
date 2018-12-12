#! /bin/bash

runBench () {
  sleep 5
  echo -e "\nBenchmarking $1\n"
  for path in text json/$1 
  do
    wrk http://localhost:$2/$path
    #wrk --timeout 30s -s pipeline.lua http://localhost:$2/$path -- 40
    echo 
  done
  kill $3
  echo "------------------------------------------"
}

nim c -r ./whipIt.nim > /dev/null 2>&1 &
runBench Whip 8000 $!

nim c -r ./beastIt.nim > /dev/null 2>&1 &
runBench HttpBeast 8080 $!

nim c -r ./jestIt.nim > /dev/null 2>&1 &
runBench Jester 5000 $!

go run gingonit.go > /dev/null &
runBench Gin-gonic 8080 $!
