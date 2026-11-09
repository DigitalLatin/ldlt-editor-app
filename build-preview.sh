
#!/usr/bin/env bash
set -euo pipefail

# Usage: ./build-preview.sh sources/cutedition.xml mutch
# Optional: SAXON_JAR=/path/to/saxon-he-11.3.jar ./build-preview.sh ...

if (( $# != 2 )); then
  echo "Usage: $0 SOURCE_XML EDITION_SLUG" >&2
  exit 2
fi

SOURCE=$1
SLUG=$2

[[ -f "$SOURCE" ]] || {
  echo "Source not found: $SOURCE" >&2
  exit 2
}

[[ "$SLUG" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || {
  echo "Slug must contain only lowercase letters, digits, underscores or hyphens" >&2
  exit 2
}

run_saxon() {
  if [[ -n "${SAXON_JAR:-}" ]]; then
    java -jar "$SAXON_JAR" "$@"
  else
    saxon "$@"
  fi
}

[[ -f xslt/validate-citestructure.xsl && -f xslt/publish.xsl ]] || {
  echo "Run from the project root containing xslt/" >&2
  exit 2
}

echo "Validating $SOURCE ..." >&2

# xsl:message writes the report to stderr.
# Errors terminate Saxon and stop the script.
run_saxon \
  -s:"$SOURCE" \
  -xsl:xslt/validate-citestructure.xsl \
  -o:/dev/null

echo "Publishing $SLUG ..." >&2

mkdir -p "_editions/$SLUG"

run_saxon \
  -s:"$SOURCE" \
  -xsl:xslt/publish.xsl \
  -o:"_editions/$SLUG/index.md" \
  "edition-slug=$SLUG"

echo "Checking Ruby dependencies ..." >&2

bundle check || bundle install

echo "Building Jekyll site ..." >&2

bundle exec jekyll build

echo "Preview build complete." >&2
