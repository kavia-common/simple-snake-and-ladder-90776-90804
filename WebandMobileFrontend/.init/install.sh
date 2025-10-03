#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-snake-and-ladder-90776-90804/WebandMobileFrontend"
cd "$WORKSPACE"
LOGDIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOGDIR"
[ -f package.json ] || { echo "package.json missing" > "$LOGDIR/install.err" && exit 2; }
# choose package manager (prefer yarn)
if command -v yarn >/dev/null 2>&1; then PM="yarn"; else PM="npm"; fi
echo "$PM" > "$LOGDIR/pm"
if [ "$PM" = "yarn" ]; then yarn -v > "$LOGDIR/pm.version" 2>&1 || true; else npm -v > "$LOGDIR/pm.version" 2>&1 || true; fi
# checksum tool
if command -v sha256sum >/dev/null 2>&1; then SHACMD=sha256sum; elif command -v sha1sum >/dev/null 2>&1; then SHACMD=sha1sum; else echo "ERROR: no checksum tool (sha256sum/sha1sum)" > "$LOGDIR/install.err" && exit 3; fi
# determine lockfile
LOCKFILE=""
if [ -f yarn.lock ]; then LOCKFILE="yarn.lock"; elif [ -f package-lock.json ]; then LOCKFILE="package-lock.json"; fi
# compute checksum of package.json + lockfile (if present)
if [ -n "$LOCKFILE" ]; then CHECKSUM=$(cat package.json "$LOCKFILE" | $SHACMD | awk '{print $1}' 2>/dev/null || true); else CHECKSUM=$($SHACMD package.json | awk '{print $1}' 2>/dev/null || true); fi
OLD_CHECKSUM=""
if [ -f "$LOGDIR/dep_checksum" ]; then OLD_CHECKSUM=$(cat "$LOGDIR/dep_checksum" || true); fi
if [ "$CHECKSUM" = "$OLD_CHECKSUM" ] && [ -d node_modules ]; then echo "deps unchanged, skipping install" > "$LOGDIR/install.log"
else
  if [ "$PM" = "yarn" ]; then
    yarn install --non-interactive --silent >"$LOGDIR/install.log" 2>"$LOGDIR/install.err" || { cat "$LOGDIR/install.err" >&2; exit 4; }
  else
    if [ -f package-lock.json ]; then
      npm ci --no-audit --no-fund --silent >"$LOGDIR/install.log" 2>"$LOGDIR/install.err" || { cat "$LOGDIR/install.err" >&2; exit 5; }
    else
      npm install --no-audit --no-fund --silent >"$LOGDIR/install.log" 2>"$LOGDIR/install.err" || { cat "$LOGDIR/install.err" >&2; exit 6; }
    fi
  fi
  echo "$CHECKSUM" > "$LOGDIR/dep_checksum"
fi
# ensure core runtime deps are present in package.json (idempotent)
node -e "try{let p=require('./package.json'); p.dependencies=p.dependencies||{}; const core={'react':'^18.2.0','react-dom':'^18.2.0','react-scripts':'^5.0.1'}; let changed=false; for(const k in core) if(!p.dependencies[k]){p.dependencies[k]=core[k]; changed=true;} if(changed){require('fs').writeFileSync('package.json',JSON.stringify(p,null,2)); console.log('PACKAGE_JSON_MODIFIED'); process.exit(0);} }catch(e){console.error(e.message); process.exit(2);}" 2>"$LOGDIR/pkg_update.err" | tee -a "$LOGDIR/pkg_update.log" || true
# if package.json was modified, re-run install and update checksum
NEW_CHECKSUM=$($SHACMD package.json | awk '{print $1}' 2>/dev/null || true)
PREV_CHK=$(cat "$LOGDIR/dep_checksum" 2>/dev/null || true)
if [ -n "$NEW_CHECKSUM" ] && [ "$NEW_CHECKSUM" != "$PREV_CHK" ]; then
  if [ "$PM" = "yarn" ]; then
    yarn install --non-interactive --silent >>"$LOGDIR/install.log" 2>>"$LOGDIR/install.err" || { cat "$LOGDIR/install.err" >&2; exit 7; }
  else
    npm install --no-audit --no-fund --silent >>"$LOGDIR/install.log" 2>>"$LOGDIR/install.err" || { cat "$LOGDIR/install.err" >&2; exit 8; }
  fi
  echo "$NEW_CHECKSUM" > "$LOGDIR/dep_checksum"
fi
# ensure dev deps: @testing-library/react and serve (install independently if missing)
for pkg in "@testing-library/react" "serve"; do
  HAS=$(node -e "try{const p=require('./package.json'); console.log(Boolean((p.devDependencies&&p.devDependencies['$pkg'])||(p.dependencies&&p.dependencies['$pkg'])));}catch(e){console.error('pkg_parse_error'); process.exit(2);} " 2>"$LOGDIR/pkg_parse.err" || true)
  if [ "$HAS" != "true" ]; then
    if [ "$PM" = "yarn" ]; then
      yarn add -D "$pkg" --silent >>"$LOGDIR/devdeps.log" 2>>"$LOGDIR/devdeps.err" || { cat "$LOGDIR/devdeps.err" >&2; exit 9; }
    else
      npm i -D "$pkg" --no-audit --no-fund --silent >>"$LOGDIR/devdeps.log" 2>>"$LOGDIR/devdeps.err" || { cat "$LOGDIR/devdeps.err" >&2; exit 10; }
    fi
  fi
done
# update final checksum (package.json + lockfile if present)
if [ -n "$LOCKFILE" ]; then FINAL_CHK=$(cat package.json "$LOCKFILE" | $SHACMD | awk '{print $1}' 2>/dev/null || true); else FINAL_CHK=$($SHACMD package.json | awk '{print $1}' 2>/dev/null || true); fi
echo "$FINAL_CHK" > "$LOGDIR/dep_checksum"
# record node/npm/yarn versions
node -v > "$LOGDIR/node.version" 2>&1 || true
npm -v > "$LOGDIR/npm.version" 2>&1 || true
if command -v yarn >/dev/null 2>&1; then yarn -v >> "$LOGDIR/pm.version" 2>&1 || true; fi
