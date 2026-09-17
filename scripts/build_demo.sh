#!/usr/bin/env bash
set -euo pipefail

# Build an HTML5/WebGL demo from the Godot project.
# Reads GODOT_BIN from .env (or falls back to godot in PATH).

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

if [[ -f .env ]]; then
    # shellcheck source=/dev/null
    export $(grep -v '^#' .env | xargs)
fi

GODOT_BIN="${GODOT_BIN:-$(command -v godot || true)}"
if [[ -z "$GODOT_BIN" ]] && [[ -x /root/.local/bin/godot ]]; then
    GODOT_BIN=/root/.local/bin/godot
fi
if [[ -z "$GODOT_BIN" ]] || [[ ! -x "$GODOT_BIN" ]]; then
    echo "ERROR: Godot binary not found. Set GODOT_BIN in .env or put godot on PATH." >&2
    exit 1
fi

BUILD_DIR="${BUILD_DIR:-build/html5}"
mkdir -p "$BUILD_DIR"

OUTPUT="$BUILD_DIR/index.html"

echo "==> Exporting HTML5 demo with $GODOT_BIN ..."
"$GODOT_BIN" --headless --path . --export-release "Web" "$OUTPUT"

# Godot ships the wasm/pck uncompressed; gzip the big payloads so the
# server can serve them with Content-Encoding: gzip (browsers decompress
# transparently). The raw files stay too as a no-accept-encoding fallback.
echo "==> Compressing payloads (gzip -9) ..."
for f in index.wasm index.pck index.js index.worker.js index.audio.worklet.js; do
    if [[ -f "$BUILD_DIR/$f" ]]; then
        gzip -9 -k -f "$BUILD_DIR/$f"
    fi
done

echo "==> Build complete: $OUTPUT"
ls -lh "$BUILD_DIR"
