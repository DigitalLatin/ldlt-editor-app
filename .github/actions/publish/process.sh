#!/bin/bash

#FILES=$(git diff --name-only $BEFORE..$AFTER | grep "sources/.*\.xml")
echo "files: $FILES"

convert() {
  echo "Converting $1"
  DIR=$(basename "$1" | sed 's/\.xml//' | tr "[:upper:]" "[:lower:]")
  if [ ! -d "_editions/$DIR" ]; then
    mkdir "_editions/$DIR"
  fi
  echo "Output to _editions/$DIR/index.md"
  saxon -s:"$1" -xsl:xslt/publish.xsl -o:"_editions/$DIR/index.md"
}

for f in $FILES
do
  echo "Processing file $f"
  convert "$f"
done  

if [ ! -z "$FILES" ]
then
  bundle install
  jekyll build
fi