#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-snake-and-ladder-90776-90804/WebandMobileFrontend"
cd "$WORKSPACE"
LOGDIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOGDIR"
EVIDENCE="$WORKSPACE/validation_evidence.txt"
PM="npm"
[ -f "$LOGDIR/pm" ] && PM=$(cat "$LOGDIR/pm" || echo npm)
# ensure serve present locally
if [ ! -f "$WORKSPACE/node_modules/.bin/serve" ]; then
  if [ "$PM" = "yarn" ]; then
    yarn add -D serve --silent >"$LOGDIR/serve.install.log" 2>"$LOGDIR/serve.install.err" || true
  else
    npm i -D serve --no-audit --no-fund --silent >"$LOGDIR/serve.install.log" 2>"$LOGDIR/serve.install.err" || true
  fi
fi
# choose serve command
SERVE_BIN=""
if [ -f "$WORKSPACE/node_modules/.bin/serve" ]; then SERVE_BIN="$WORKSPACE/node_modules/.bin/serve"; fi
if [ -z "$SERVE_BIN" ]; then
  if [ "${ALLOW_NETWORK_FETCH:-0}" = "1" ]; then SERVE_CMD="npx --yes serve -s build -l 3000"; else echo "serve not installed and network fetch disabled" > "$LOGDIR/serve.err" && echo "serve_missing" > "$EVIDENCE" && exit 12; fi
else
  SERVE_CMD="$SERVE_BIN -s build -l 3000"
fi
LOGFILE="$LOGDIR/serve.log"
# start server under setsid to create process group; run in background
setsid bash -lc "$SERVE_CMD" >"$LOGFILE" 2>&1 &
PID=$!
# record PGID for later group termination
PGID=$(ps -o pgid= $PID | tr -d ' ' || true)
printf "%s\n" "$PID" > "$LOGDIR/serve.pid"
printf "%s\n" "$PGID" > "$LOGDIR/serve.pgid"
# give small buffer for process to spawn
sleep 0.5
printf "start_pid=%s\npgid=%s\nlog=%s\n" "$PID" "$PGID" "$LOGFILE" > "$LOGDIR/serve.start.info"
