# LLM Agent Containers (with claude-flow focus)

This repo provides containerized CLIs for day‑to‑day agent work: Anthropic Claude Code ("claude"), claude-flow, OpenAI Codex, Google Gemini, and ruv-swarm. The primary workflow going forward is claude-flow, run inside a Docker image that mounts only your current repo (plus a small set of dot-configs). This is not perfect isolation; it does an ok job at isolating non‑malicious actions and keeping most operations scoped to your project while preserving claude-flow’s expected "full access" experience inside the container.


**Why This Exists**
- claude-flow expects unrestricted local access (spawn processes, write files, cache deps, npx installs).
- We prefer it generally sticks to the current repo; running in Docker with a narrow bind mount achieves a practical middle‑ground.
- The image also addresses Node native module drift (better-sqlite3) so tools like ruv-swarm work reliably.


**What You Get**
- `ryanjarv/claude`: Ubuntu-based image with:
  - Global `@anthropic-ai/claude-code` (`claude`) and `claude-flow@2.7.14`.
  - Prebuilt `better-sqlite3` and rebuild safeguards.
  - Optional `ruv-swarm` preinstall (+ rebuild).
- `sh_functions`: shell wrappers (`claude`, `claude-flow`, `ruv-swarm`, `codex`, `gemini`) that run the right container with your repo mounted and working directory preserved.
- A local `./claude-flow` wrapper for host use if you prefer npx/global Node instead of Docker.


**Quick Start**
- Prereqs: Docker (Buildx recommended), a shell that can `source` files.
- Optional: set `ANTHROPIC_API_KEY` in your shell, or configure `~/.claude*` on the host (these are mounted in the container).

1) Build the images (or pull):
- All images: `./build.sh`
- Just Claude: `docker buildx build -t ryanjarv/claude -f claude/Dockerfile ./claude`
- Or pull: `docker pull ryanjarv/claude:latest`

2) Load the helper functions in your shell:
- One‑off in current shell: `source sh_functions`
- Persistent: add `source /path/to/repo/sh_functions` to your shell profile.

3) Verify the toolchain:
- `claude --help` (Anthropic CLI inside container)
- `claude-flow --help` (claude-flow CLI inside the same container)


**Everyday claude-flow Usage**
- Run commands from the project you want claude-flow to operate on.
- The wrapper shares only the current Git repo root (or your current directory if not in a Git repo) into the container and sets the working dir to match your host PWD.

Examples:
- Explore modes: `claude-flow sparc modes`
- TDD flow: `claude-flow sparc tdd "Add user login"`
- One-off task: `claude-flow sparc run architect "Design the plugin system"`

Advanced (Claude desktop integration): see `CLAUDE.md` for MCP setup and usage.


**How Isolation Works (and its Limits)**
- The shell wrappers compute `DOCKER_SHARE_ROOT` as your Git top‑level (fallback: current directory) and mount it read‑write at the same path in the container; `-w "$PWD"` keeps working dir aligned.
- Minimal extra mounts: `/tmp` (host), `~/.claude*`, and `~/.claude-flow` for credentials/config/caches.
- Result: claude-flow can do “anything” inside the container, but host visibility is mostly limited to your repo + `/tmp` + the mounted dot-dirs.
- Threat model: accidental overreach, not adversarial code. It’s meant to nudge claude-flow to stay within the repo, not to withstand a determined escape.
- Not a security boundary: the container has network access and can write to mounted paths. Be sure you run from the intended repo directory.

Safety tips:
- Always invoke wrappers from inside the repo you want to share.
- If you run them from outside a Git repo, your current directory will be shared. Avoid running from `$HOME` if you want tight scoping.


**What the Wrappers Actually Do**
- File: `sh_functions`
  - `set_docker_share_root_env`: sets and logs the path being shared (Git root or `$PWD`).
  - `claude-flow`: runs `docker run --rm -it` using image `ryanjarv/claude`, mounts the share root and dot-configs, sets `-w "$PWD"`, and overrides entrypoint to `/usr/local/bin/claude-flow`.
  - `claude`: same image, default entrypoint (see below), passes `--dangerously-skip-permissions` to reduce interactive prompts.
  - `ruv-swarm`, `codex`, `gemini`: convenience wrappers for other images.
- File: `claude/claude-entrypoint.sh`
  - On container start, walks upward from `PWD` and through the NPX cache to detect/repair `better-sqlite3` ABI mismatches (`npm rebuild better-sqlite3`).
  - Then execs the `claude` binary.
- File: `claude/Dockerfile`
  - Installs Node 22 via nvm, `@anthropic-ai/claude-code`, `claude-flow@2.7.14`, and prebuilds `better-sqlite3` for both claude-flow and ruv-swarm; seeds NPX cache to avoid runtime build errors.

Note: The claude-flow wrapper uses the container but bypasses the entrypoint (it sets `--entrypoint /usr/local/bin/claude-flow`). The image prebuilds `better-sqlite3` to make this safe.


**Host Wrapper (Optional)**
- File: `./claude-flow`
  - Forces `PWD` and `CLAUDE_WORKING_DIR` to your current project, then executes:
    - local `node_modules/.bin/claude-flow` if present,
    - or monorepo parent’s `node_modules/.bin/claude-flow`,
    - or global `claude-flow` if installed,
    - or `npx --yes claude-flow@2.7.14`.
  - Use it if you prefer running directly on the host; you lose the repo‑scoped container boundary.
  - Note: if you’ve `source`d `sh_functions`, the shell function named `claude-flow` takes precedence. Run `./claude-flow ...` to force the host wrapper, or rename one of them per your workflow.


**Credentials & Config**
- Provide `ANTHROPIC_API_KEY` via env or host `~/.claude*` files. The container mounts:
  - `~/.claude`, `~/.claude.json`, `~/.claude.json.backup`
  - `~/.claude-flow`
- These locations allow both `claude` and `claude-flow` to authenticate without baking secrets into images.


**Build, Test, Push**
- Build all: `./build.sh`
- Build specific: `docker buildx build -t ryanjarv/claude -f claude/Dockerfile ./claude`
- Smoke test: `docker run --rm -it -v "$PWD:$PWD" -w "$PWD" ryanjarv/claude --help`
- Push: `./push.sh`

If you prefer Make targets, adapt these to `make build` / `make push`.


**Troubleshooting**
- better-sqlite3 errors: use the containerized wrappers. The image prebuilds and the Claude entrypoint auto‑rebuilds on ABI mismatch. See `claude/TESTING-BETTER-SQLITE3.md` and `claude/quick-test.sh`.
- Unexpected file access: confirm you’re in the correct Git repo; the wrapper logs the shared path. Avoid running from `$HOME`.
- Permissions prompts from Claude CLI: the `claude` wrapper passes `--dangerously-skip-permissions` to reduce friction.


**Related Images**
- `ryanjarv/codex`: `codex` CLI with dev tools (Alpine).
- `ryanjarv/gemini`: Python base with `google-generativeai`.
- `ryanjarv/ruv-swarm`: Ubuntu + Node 20, global claude/claude-flow; primarily for experiments.


**Notes for Contributors**
- Keep new tooling inside the matching agent directory (e.g., `claude/`).
- Rebuild touched images to catch dependency drift.
- Don’t hardcode credentials; rely on env vars or host‑mounted configs.
- Follow Dockerfile style (uppercase directives, tidy RUNs) and clear shell diagnostics.
