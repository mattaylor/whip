#! /bin/bash

apps="whipit beastit jestit mofuit gingonit"
build=0
runBench () {
  ./$1 > /dev/null 2>&1 &
  pid=$!
  sleep 2
  echo -e "\nBenchmarking $1\n"
  for path in text json/$1; do
    wrk http://localhost:8080/$path
    #wrk --timeout 30s -s pipeline.lua http://localhost:$2/$path -- 40
    echo 
  done
  kill -9 $pid
  sleep 1
  echo "------------------------------------------"
}

cd tests

if [ "$1" == "-c" ]; then
  build=1
  shift
fi

if [ $# -ne 0 ]; 
  then apps=$@ 
fi

if [ $build == 1 ]; then
  for app in $apps; do
    echo "Compiling $app"
    case $app in
      mofuit) nim c --threads:on mofuit > /dev/null;;
      gingonit) go build gingonit.go;;
      *) nim c $app > /dev/null;;
    esac
  done
fi

for app in $apps; do
  runBench $app
done
