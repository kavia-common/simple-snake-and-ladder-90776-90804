#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-snake-and-ladder-90776-90804/WebandMobileFrontend"
cd "$WORKSPACE"
LOGDIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOGDIR"
EVIDENCE="$WORKSPACE/validation_evidence.txt"
# run build (using build script above)
./.init_build_runner.sh || true
# start server
./.init_start_runner.sh || true
# probe server
TIMEOUT=30
SLEEP=1
ELAPSED=0
HTTP=000
while [ $ELAPSED -lt $TIMEOUT ]; do
  if command -v curl >/dev/null 2>&1; then HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/ || echo 000)
  elif command -v wget >/dev/null 2>&1; then HTTP=$(wget -qS --spider http://127.0.0.1:3000/ 2>&1 | awk '/HTTP\//{print $2; exit}' || echo 000)
  else HTTP=000; fi
  if [ "$HTTP" != "000" ]; then break; fi
  sleep $SLEEP; ELAPSED=$((ELAPSED+SLEEP));
done
LOGFILE="$LOGDIR/serve.log"
PID=""
if [ -f "$LOGDIR/serve.pid" ]; then PID=$(cat "$LOGDIR/serve.pid" 2>/dev/null || true); fi
printf "http_status=%s\nstart_pid=%s\nlog=%s\n" "$HTTP" "$PID" "$LOGFILE" > "$EVIDENCE"
head -n 200 "$LOGFILE" > "$LOGDIR/serve_head.log" 2>/dev/null || true
# stop server
./.init_stop_runner.sh || true
# output evidence
cat "$EVIDENCE" || true
