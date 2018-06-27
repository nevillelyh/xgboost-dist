#!/bin/bash

check_env() {
  missing=()
  for v in $*; do
    if [ -z ${!v} ]; then
      missing+=($v)
    fi
  done
  l=${#missing[@]}
  if [ $l -ne 0 ]; then
    [ $l -ge 2 ] && s="s"
    echo "Missing environment variable$s: ${missing[*]}"
    exit 1
  fi
}

check_env SONATYPE_USERNAME SONATYPE_PASSWORD

export SONATYPE_SNAPSHOT_URL="https://oss.sonatype.org/content/repositories/snapshots"
export SONATYPE_RELEASES_URL="https://oss.sonatype.org/content/repositories/releases"

UNAME="$(uname -s)"
CMAKE_URL="https://cmake.org/files/v3.11/cmake-3.11.4-$UNAME-x86_64.tar.gz"
MAVEN_URL="http://apache.spinellicreations.com/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz"

if [ "$UNAME" == "Darwin" ]; then
  CMAKE_BIN="CMake.app/Contents/bin"
  OS="osx"
elif [ "$UNAME" == "Linux" ]; then
  CMAKE_BIN="bin"
  OS="linux"
else
  echo "Unkonwn uname $UNAME"
  exit 1
fi

if [ ! $(command -v mvn >/dev/null) ]; then
  curl -s $MAVEN_URL | tar xzf -
  export PATH="$(pwd)/$(ls | grep maven)/bin":$PATH
fi

if [ ! $(command -v cmake >/dev/null) ]; then
  curl -s $CMAKE_URL | tar xzf -
  export PATH="$(pwd)/$(ls | grep cmake)/$CMAKE_BIN":$PATH
fi

cd xgboost/jvm-packages
git reset --hard
export POM_VERSION=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:exec | tr -d '\n')
export GIT_HASH=$(git rev-parse --short=8 HEAD)
cd ../..
