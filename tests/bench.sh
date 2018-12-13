#! /bin/bash

apps=(whipit beastit) # jestit)
runBench () {
  ./$1 > /dev/null 2>&1 &
  pid=$!
  echo -e "\nBenchmarking $1\n"
  sleep 5
  for path in text json/$1; do
    wrk http://localhost:8080/$path
    #wrk --timeout 30s -s pipeline.lua http://localhost:$2/$path -- 40
    echo 
  done
  kill -9 $pid
  echo "------------------------------------------"
}

if [ "$1" == "-c" ]; then
  for app in ${apps[@]}; do
    echo "Compiling $app" 
    nim c $app > /dev/null 2>&1
  done
  nim c --threads:on mofuit > /dev/null 2>&1
  go build gingonit.go 
fi

for app in ${apps[@]}; do
  runBench $app
done
runBench mofuit
runBench gingonit
