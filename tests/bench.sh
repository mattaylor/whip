#! /bin/bash

runBench () {
  sleep 5
  echo -e "\nBenchmarking $1\n"
  for path in text json/$1 
  do
    wrk --timeout 20s http://localhost:$2/$path
    #wrk --timeout 30s -s pipeline.lua http://localhost:$2/$path -- 40
    echo 
  done
  kill -9 $3
  echo "------------------------------------------"
}

nim c whipIt.nim > /dev/null 2>&1
nim c beastIt.nim > /dev/null 2>&1
nim c jestIt.nim > /dev/null 2>&1
go build gingonit.go 

./whipIt > /dev/null 2>&1 &
runBench Whip 8000 $!

./beastIt > /dev/null 2>&1 &
runBench Beast 8080 $!

./jestIt > /dev/null 2>&1 &
runBench Jester 5000 $!

./gingonIt > /dev/null &
runBench Gingonic 8080 $!