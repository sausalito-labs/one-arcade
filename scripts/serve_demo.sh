#!/usr/bin/env bash
set -euo pipefail

# Build and serve the HTML5/WebGL demo.
# Reads GODOT_BIN, DEMO_HOST, and DEMO_PORT from .env.
# Usage:
#   ./scripts/serve_demo.sh           # build once then serve
#   ./scripts/serve_demo.sh --build   # force rebuild before serving
#   ./scripts/serve_demo.sh --serve   # serve existing build without rebuilding

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ -f .env ]]; then
    # shellcheck source=/dev/null
    export $(grep -v '^#' .env | xargs)
fi

DEMO_HOST="${DEMO_HOST:-0.0.0.0}"
DEMO_PORT="${DEMO_PORT:-8765}"
BUILD_DIR="${BUILD_DIR:-build/html5}"
INDEX="$BUILD_DIR/index.html"

MODE="build-and-serve"
if [[ "${1:-}" == "--build" ]]; then
    MODE="build-and-serve"
elif [[ "${1:-}" == "--serve" ]]; then
    MODE="serve-only"
fi

if [[ "$MODE" == "build-and-serve" ]]; then
    ./scripts/build_demo.sh
fi

if [[ ! -f "$INDEX" ]]; then
    echo "ERROR: No build found at $INDEX. Run ./scripts/build_demo.sh first." >&2
    exit 1
fi

# Determine a reachable URL to print.
ACCESS_HOST="$DEMO_HOST"
if [[ "$ACCESS_HOST" == "0.0.0.0" ]]; then
    ACCESS_HOST="$(hostname -I | awk '{print $1}')"
fi

echo ""
echo "==> Serving HTML5 demo at http://$ACCESS_HOST:$DEMO_PORT/"
echo "    Bind: $DEMO_HOST:$DEMO_PORT"
echo "    Press Ctrl+C to stop"
echo ""

python3 -m http.server "$DEMO_PORT" --bind "$DEMO_HOST" --directory "$BUILD_DIR"
