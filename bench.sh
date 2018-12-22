#! /bin/bash

apps="whipit beastit jestit mofuit gingonit fastit"
build=0
runBench () {
  ./$1 > /dev/null 2>&1 &
  pid=$!
  sleep 2
  echo -e "\nBenchmarking $1\n"
  for path in text text/$1 json/$1
  do
    wrk http://localhost:8080/$path | grep -E 'Requests/sec|Non-2xx|Running|SocketErrors'
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
