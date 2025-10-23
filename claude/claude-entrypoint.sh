#!/bin/sh
# Rebuild better-sqlite3 when the native module was compiled against a different Node ABI.
set -e

rebuild_if_needed() {
  dir="$1"
  pkg_dir="$dir/node_modules/better-sqlite3"

  if [ ! -d "$pkg_dir" ]; then
    return
  fi

  NODE_PATH="$dir/node_modules${NODE_PATH:+:$NODE_PATH}" node -e "
    try {
      require('better-sqlite3');
      process.exit(0);
    } catch (err) {
      if (err && err.code === 'ERR_DLOPEN_FAILED') {
        if (err.message && err.message.includes('NODE_MODULE_VERSION')) {
          process.exit(1);
        }
      }
      if (err && err.code === 'MODULE_NOT_FOUND') {
        process.exit(1);
      }
      process.exit(0);
    }
  " >/dev/null 2>&1

  status=$?
  if [ "$status" -ne 0 ]; then
    node_version="$(node -v 2>/dev/null || echo "<unknown>")"
    echo "[claude-entrypoint] Rebuilding better-sqlite3 in $dir for Node $node_version" >&2
    if ! (cd "$dir" && npm rebuild better-sqlite3 >/dev/null 2>&1); then
      echo "[claude-entrypoint] Warning: failed to rebuild better-sqlite3 in $dir" >&2
    fi
  fi
}

walk_up_and_rebuild() {
  current="$1"

  while [ "$current" != "/" ]; do
    rebuild_if_needed "$current"
    next="$(dirname "$current")"
    if [ "$next" = "$current" ]; then
      break
    fi
    current="$next"
  done
}

scan_for_cached_modules() {
  root="$1"

  if [ ! -d "$root" ]; then
    return
  fi

  find "$root" -type d -path '*/node_modules/better-sqlite3' 2>/dev/null | while IFS= read -r module_dir; do
    dir="${module_dir%/node_modules/better-sqlite3}"
    rebuild_if_needed "$dir"
  done
}

if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
  start_dir="$(pwd 2>/dev/null || echo "/")"
  walk_up_and_rebuild "$start_dir"
  if [ -n "${HOME:-}" ]; then
    scan_for_cached_modules "${HOME}/.npm/_npx"
  fi
else
  echo "[claude-entrypoint] Skipping better-sqlite3 rebuild checks (node/npm unavailable)" >&2
fi

claude_bin="$(command -v claude 2>/dev/null || true)"

if [ -n "$claude_bin" ]; then
  exec "$claude_bin" "$@"
fi

echo "[claude-entrypoint] Error: unable to locate claude executable" >&2
exit 127
