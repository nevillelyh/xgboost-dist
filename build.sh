#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/common.sh"

UNAME="$(uname -s)"
if [ "$UNAME" == "Linux" ]; then
  # hack to make sure OpenMP is available on Linux, useful in distributed
  # systems, e.g. Dataflow
  GOMP_PATH=$(ldconfig -p | grep libgomp.so.1 | awk '{print $4}')
  mkdir -p xgboost/jvm-packages/xgboost4j/src/main/resources/lib
  cp $GOMP_PATH xgboost/jvm-packages/xgboost4j/src/main/resources/lib
fi

cd xgboost
./build.sh

cd jvm-packages
VERSION="$POM_VERSION-$GIT_HASH-$OS-SNAPSHOT"
mvn versions:set -DnewVersion=$VERSION
mvn -pl xgboost4j clean package

mvn deploy:deploy-file --settings ../../settings.xml \
  -DrepositoryId=ossrh -Durl=$SONATYPE_SNAPSHOT_URL \
  -DgroupId=me.lyh -DartifactId=xgboost4j -Dversion=$VERSION \
  -DgeneratePom=true -Dpackaging=jar \
  -Dfile=xgboost4j/target/xgboost4j-$VERSION.jar
