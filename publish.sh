#!/bin/bash

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/common.sh"

DATE=$(date +"%Y%m%d")
VERSION="$POM_VERSION-$DATE-$GIT_HASH-SNAPSHOT"

echo -n "Version [$VERSION]: "
read version
[ ! -z "$version" ] && VERSION=$version

PUBLISH_URL=$SONATYPE_RELEASES_URL
(echo $VERSION | grep -Eq ".*-SNAPSHOT$") && PUBLISH_URL=$SONATYPE_SNAPSHOT_URL

rm -rf artifacts assembly
mkdir artifacts assembly
cd assembly
for OS in osx linux; do
  OS_VERSION="$POM_VERSION-$GIT_HASH-$OS-SNAPSHOT"
  mvn dependency:get \
    -DremoteRepositories=$SONATYPE_SNAPSHOT_URL \
    -DgroupId=me.lyh -DartifactId=xgboost4j -Dversion=$OS_VERSION
  jar -xf ${HOME}/.m2/repository/me/lyh/xgboost4j/$OS_VERSION/xgboost4j-$OS_VERSION.jar
done

jar -cf "../artifacts/xgboost4j-$VERSION.jar" .
cd ..

cd pom
mvn versions:set -DnewVersion=$VERSION
cd ..
mvn deploy:deploy-file --settings settings.xml \
  -DrepositoryId=ossrh -Durl=$PUBLISH_URL \
  -DgroupId=me.lyh -DartifactId=xgboost4j -Dversion=$VERSION \
  -DpomFile=pom/pom.xml -Dpackaging=jar \
  -Dfile=artifacts/xgboost4j-$VERSION.jar

git reset --hard
