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

cd xgboost/jvm-packages
git reset --hard
export POM_VERSION=$(mvn -q -Dexec.executable=echo -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:exec | tr -d '\n')
export GIT_HASH=$(git rev-parse --short=8 HEAD)
cd ../..
