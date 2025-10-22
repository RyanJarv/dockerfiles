# Repository Guidelines

## Project Structure & Module Organization
The root `Makefile` builds and pushes the agent images (`claude`, `codex`, `gemini`, `ruv-swarm`), while `tmp/` stays ignored for local scratch space. Each agent directory holds its Dockerfile; `claude/` also includes `claude-entrypoint.sh`, which rebuilds `better-sqlite3` when the host ABI changes. Shared shell helpers live in `sh_functions` and are sourced via `install.sh`; keep new tooling nestled inside the matching agent directory so diffs stay narrow.

## Build, Test, and Development Commands
Use `make build` for a full rebuild and `make push` once images are verified. Targeted builds should call `docker build -t ryanjarv/claude claude/` (swap the agent name as needed). After edits, run `docker run --rm -it ryanjarv/claude --help` or the equivalent command to confirm the entrypoint resolves, and execute `make install` once so local shells pick up the helper functions.

## Coding Style & Naming Conventions
Dockerfiles rely on uppercase directives, four-space indentation for continued commands, and RUN blocks that finish by clearing package caches (`rm -rf /var/lib/apt/lists/*`). Shell scripts stay POSIX `sh`, begin with `set -e`, and emit friendly diagnostics around docker invocations (mirroring `sh_functions`). Keep image tags in the `ryanjarv/<agent>` form and mirror function names after the agent (`claude()`, `codex()`), reserving hyphenated aliases such as `ruv-swarm()` for public CLIs.

## Testing Guidelines
Always rebuild the touched image (`docker build --pull -t ryanjarv/claude claude/`) to surface dependency drift. Launch the image with its intended command—`claude` and `ruv-swarm` should reach the Anthropic CLI, while `gemini` should open a Python session with `google-generativeai` importable. Watch `claude-entrypoint` logs for a successful `better-sqlite3` rebuild and run `shellcheck` locally when editing shared helper scripts.

## Commit & Pull Request Guidelines
Commit subjects should stay under 50 characters, use a scope prefix when relevant (`claude: refresh NodeSource key`), and limit each commit to a single agent. Pull requests must list the affected images, the build/run commands executed, and any follow-up actions (registry pushes, doc updates). Include concise logs or screenshots when solving runtime issues so reviewers can reproduce the fix quickly.

## Security & Configuration Tips
Never bake credentials or personal API keys into images; mount them at runtime or rely on env vars. Pin new global tooling versions and flush package caches so layers remain small. When fetching remote scripts (curl | sh), document the source and fingerprint in a nearby comment to aid future audits.
