#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-snake-and-ladder-90776-90804/WebandMobileFrontend"
LOGDIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOGDIR"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
valid_pkg=false
if [ -f package.json ]; then
  if node -e "try{const p=require('./package.json'); if(p.name&&p.scripts&&p.scripts.start) process.exit(0); else process.exit(1);}catch(e){process.exit(2)}" >/dev/null 2>&1; then valid_pkg=true; fi
fi
if [ "$valid_pkg" = true ]; then echo "existing valid package.json" > "$LOGDIR/scaffold.log"; exit 0; fi
if command -v create-react-app >/dev/null 2>&1; then
  create-react-app --version > "$LOGDIR/cra.version" 2>&1 || true
  TMPDIR=$(mktemp -d)
  if create-react-app app --use-npm >/dev/null 2>"$LOGDIR/scaffold.err"; then
    cp -a "$TMPDIR/app/." "$WORKSPACE/" || true
    rm -rf "$TMPDIR"
    echo "scaffolded via global CRA" > "$LOGDIR/scaffold.log"
    exit 0
  else
    rm -rf "$TMPDIR"
    echo "global CRA failed" > "$LOGDIR/scaffold.err"
  fi
fi
if [ "${ALLOW_NETWORK_FETCH:-0}" = "1" ]; then
  if npx --yes create-react-app@latest app --use-npm >/dev/null 2>"$LOGDIR/scaffold.err"; then
    cp -a app/. "$WORKSPACE/" || true; rm -rf app; echo "scaffolded via npx CRA" > "$LOGDIR/scaffold.log"; exit 0
  fi
fi
cat > package.json <<'EOF'
{
  "name": "webandmobile-frontend",
  "version": "0.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "^5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test --watchAll=false"
  }
}
EOF
mkdir -p src public
cat > src/App.js <<'EOF'
import React from 'react';
export default function App(){return <div id="root">Hello</div>}
EOF
cat > src/index.js <<'EOF'
import React from 'react';
import {createRoot} from 'react-dom/client';
import App from './App';
const el=document.getElementById('root')||document.createElement('div'); el.id='root'; document.body.appendChild(el);
createRoot(el).render(<App/>);
EOF
cat > public/index.html <<'EOF'
<!doctype html><html><head><meta charset="utf-8"><title>App</title></head><body><div id="root"></div></body></html>
EOF
cat > .env <<'EOF'
HOST=0.0.0.0
BROWSER=none
PORT=3000
EOF
echo "seed_app_created" > "$LOGDIR/scaffold.log"
