#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-snake-and-ladder-90776-90804/WebandMobileFrontend"
cd "$WORKSPACE"
LOGDIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOGDIR"
PM="npm"
[ -f "$LOGDIR/pm" ] && PM=$(cat "$LOGDIR/pm" || echo npm)
if [ "$PM" = "yarn" ]; then
  yarn build >"$LOGDIR/build.log" 2>&1 || { cat "$LOGDIR/build.log" >&2; echo "build_failed" > "$WORKSPACE/validation_evidence.txt"; exit 10; }
else
  npm run build >"$LOGDIR/build.log" 2>&1 || { cat "$LOGDIR/build.log" >&2; echo "build_failed" > "$WORKSPACE/validation_evidence.txt"; exit 11; }
fi
