
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

SOURCE="sources/cutedition.xml"
PREVIEW_URL="http://localhost:4000"

usage() {
  cat <<EOF
LDLT local edition preview

Usage:
  ./preview.sh build XML_PATH EDITION_SLUG
  ./preview.sh serve
  ./preview.sh stop
  ./preview.sh status
  ./preview.sh logs

Examples:
  ./preview.sh build ~/editions/cutedition.xml mutch
  ./preview.sh serve

Preview URL: $PREVIEW_URL
EOF
}

command="${1:-help}"

case "$command" in
  
  build)
    if (( $# != 3 )); then
      usage >&2
      exit 2
    fi

    xml_path="$2"
    slug="$3"

    if [[ ! -f "$xml_path" ]]; then
      echo "XML file not found: $xml_path" >&2
      exit 2
    fi

    xml_path="$(cd "$(dirname "$xml_path")" && pwd)/$(basename "$xml_path")"

    # Create a temporary Compose override containing the
    # edition-specific read-only bind mount.
    override=$(mktemp "${TMPDIR:-/tmp}/ldlt-compose.XXXXXX.yaml")
    trap 'rm -f "$override"' EXIT

    # Quote the path safely for YAML.
    escaped_path=${xml_path//\'/\'\'}

    cat > "$override" <<EOF
services:
  preview:
    volumes:
      - type: bind
        source: '$escaped_path'
        target: /site/sources/cutedition.xml
        read_only: true
EOF

    echo "Building edition: $slug"
    echo "Source: $xml_path"

    docker compose \
      -f compose.yaml \
      -f "$override" \
      run --rm --no-deps preview \
      bash build-preview.sh sources/cutedition.xml "$slug"

    echo "Build complete."
    ;;

  serve)
    if (( $# != 1 )); then
      usage >&2
      exit 2
    fi

    docker compose up -d --no-build preview
    echo "Preview available at $PREVIEW_URL"
    ;;

    stop)
    docker compose stop preview
    ;;

  status)
    docker compose ps
    ;;

  logs)
    docker compose logs --tail=100 -f preview
    ;;

  help|-h|--help)
    usage
    ;;

  *)
    echo "Unknown command: $command" >&2
    usage >&2
    exit 2
    ;;
esac
