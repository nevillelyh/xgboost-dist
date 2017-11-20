#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/common.sh"

UNAME="$(uname -s)"
if [ "$UNAME" == "Darwin" ]; then
  CMAKE_BIN="CMake.app/Contents/bin"
  OS="osx"
elif [ "$UNAME" == "Linux" ]; then
  CMAKE_BIN="bin"
  OS="linux"

  # hack to make sure OpenMP is available on Linux, useful in distributed
  # systems, e.g. Dataflow
  GOMP_PATH=$(ldconfig -p | grep libgomp.so.1 | awk '{print $4}')
  mkdir -p xgboost/jvm-packages/xgboost4j/src/main/resources/lib
  cp $GOMP_PATH xgboost/jvm-packages/xgboost4j/src/main/resources/lib
else
  echo "Unkonwn uname $UNAME"
  exit 1
fi
CMAKE_URL="https://cmake.org/files/v3.10/cmake-3.10.0-$UNAME-x86_64.tar.gz"
MAVEN_URL="http://www-us.apache.org/dist/maven/maven-3/3.5.2/binaries/apache-maven-3.5.2-bin.tar.gz"

if [ ! $(command -v mvn >/dev/null) ]; then
  curl -s $MAVEN_URL | tar xzf -
  export PATH="$(pwd)/$(ls | grep maven)/bin":$PATH
fi

if [ ! $(command -v cmake >/dev/null) ]; then
  curl -s $CMAKE_URL | tar xzf -
  export PATH="$(pwd)/$(ls | grep cmake)/$CMAKE_BIN":$PATH
fi

cd xgboost/jvm-packages
VERSION="$POM_VERSION-$GIT_HASH-$OS-SNAPSHOT"
mvn versions:set -DnewVersion=$VERSION
mvn -pl xgboost4j clean package

mvn deploy:deploy-file --settings ../../settings.xml \
  -DrepositoryId=ossrh -Durl=$SONATYPE_SNAPSHOT_URL \
  -DgroupId=me.lyh -DartifactId=xgboost4j -Dversion=$VERSION \
  -DgeneratePom=true -Dpackaging=jar \
  -Dfile=xgboost4j/target/xgboost4j-$VERSION.jar
