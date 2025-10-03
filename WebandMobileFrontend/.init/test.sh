#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/simple-snake-and-ladder-90776-90804/WebandMobileFrontend"
cd "$WORKSPACE"
LOGDIR="$WORKSPACE/.setup_logs"; mkdir -p "$LOGDIR"
PM="npm"
[ -f "$LOGDIR/pm" ] && PM=$(cat "$LOGDIR/pm" || echo npm)
# ensure src and App exist
mkdir -p src
if [ -f tsconfig.json ]; then APP_SRC=src/App.tsx; TEST_FILE=src/App.test.tsx; else APP_SRC=src/App.js; TEST_FILE=src/App.test.js; fi
if [ ! -f "$APP_SRC" ]; then cat > "$APP_SRC" <<'EOF'
import React from 'react';
export default function App(){return <div>Stub App</div>}
EOF
fi
if [ ! -f "$TEST_FILE" ]; then cat > "$TEST_FILE" <<'EOF'
import React from 'react';
import { render } from '@testing-library/react';
import App from './App';

test('renders without crashing', () => {
  render(<App />);
});
EOF
fi
# ensure a runnable test command: prefer project-local react-scripts or jest, otherwise add vitest as deterministic fallback
HAS_RUNNER=0
if [ -f node_modules/.bin/react-scripts ] || [ -f node_modules/.bin/jest ]; then HAS_RUNNER=1; fi
if [ "$HAS_RUNNER" -ne 1 ]; then
  # install vitest as lightweight runner non-interactively
  if [ "$PM" = "yarn" ]; then
    yarn add -D vitest jsdom @testing-library/react --silent >"$LOGDIR/devdeps.log" 2>"$LOGDIR/devdeps.err" || { cat "$LOGDIR/devdeps.err" >&2; exit 11; }
  else
    npm i -D vitest jsdom @testing-library/react --no-audit --no-fund --silent >"$LOGDIR/devdeps.log" 2>"$LOGDIR/devdeps.err" || { cat "$LOGDIR/devdeps.err" >&2; exit 12; }
  fi
  # add test script if missing
  node -e "try{const f=require('./package.json'); f.scripts=f.scripts||{}; if(!f.scripts.test){f.scripts.test='vitest'; require('fs').writeFileSync('package.json',JSON.stringify(f,null,2));} }catch(e){console.error(e); process.exit(2)}" 2>"$LOGDIR/pkg_parse.err" || { cat "$LOGDIR/pkg_parse.err" >&2; }
fi
export CI=true
TEST_LOG="$LOGDIR/test.log"
# run tests non-interactively and capture output
if [ "$PM" = "yarn" ]; then
  yarn test --silent --watchAll=false >"$TEST_LOG" 2>&1 || { cat "$TEST_LOG" >&2; exit 13; }
else
  # pass watchAll=false to common runners; for npm, use the -- separator
  npm test --silent -- --watchAll=false >"$TEST_LOG" 2>&1 || { cat "$TEST_LOG" >&2; exit 14; }
fi
