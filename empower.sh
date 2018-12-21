#! /bin/bash

apps="whipower fastpower"
build=0
runBench () {
  ./$1 > /dev/null 2>&1 &
  pid=$!
  sleep 2
  echo -e "\nBenchmarking $1\n"
  #for path in plaintext json db fortune queries?queries=10  update?queries=10
  for path in plaintext fortune queries?queries=10  update?queries=10
  #for path in plaintext queries\?queries\=10
  do
    #wrk -c 256 -t 8 -d 20s -s pipeline.lua http://localhost:8080/$path -- 40
    wrk -d 5s http://localhost:8080/$path
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
elif [ "$1" == "-ct" ]; then
  build=1
  opts="--threads:on"
  shift
fi

if [ $# -ne 0 ]; 
  then apps=$@ 
fi

if [ $build == 1 ]; then
  for app in $apps; do
    echo "Building $app"
    case $app in
      mofuit) nim c --threads:on mofuit > /dev/null;;
      gingonit) go build gingonit.go;;
      fastit) go build fastit.go;;
      *) nim c $opts $app > /dev/null;;
    esac
  done
fi

for app in $apps; do
  runBench $app
done
