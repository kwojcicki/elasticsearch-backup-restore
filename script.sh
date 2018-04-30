#!/bin/bash
REPONAME="REPONAME"
ELASTICIP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' solution_elastic_1)


create() {
  if [ -z ${2} ]; then
    printf "Usage: $0 {create} {snapshot-name} {optional, indices to include}\n"
    exit 1
  fi

  printf "Generating Repo to store snapshot\n"
  REPOSTATUS=$(curl --silent --head -XGET ''"${ELASTICIP}"':9200/_snapshot/'"${REPONAME}"'?pretty' | grep "200")
  if [ -z "${REPOSTATUS}" ]; then
    printf "Creating repo to store snapshots\n"
    curl -XPUT "http://${ELASTICIP}:9200/_snapshot/${REPONAME}" -H "Content-Type: application/json" -d "{ \
      \"type\": \"fs\", \
      \"settings\": { \
        \"location\": \"tmp\", \
        \"compress\": true \
      }\
    }"
  else 
    printf "Repo already exists moving on to generating snapshot\n"
  fi


  INDICES="node-metrics-5min-2018.04.27-4"

  if ! [ -z ${3} ]; then
    INDICES="${3}"
  fi
  printf "\nCreating snapshot\n"
  curl -XPUT "${ELASTICIP}:9200/_snapshot/${REPONAME}/${2}?wait_for_completion=true&pretty" -H "Content-Type: application/json" -d" { \
    \"indices\": \"${INDICES}\", \
    \"ignore_unavailable\": true, \
    \"include_global_state\": false \
  }"
}

if [  "$(type -t $1)" = function ]; then
  eval $1 "$@"
else
  printf "Usage: $0 {create}, {snapshotname}, {indices to snapshot}\n"
fi