# syntax=docker/dockerfile:1.7-labs

FROM ryanjarv/ubuntu:latest

# Install additional build dependencies for better-sqlite3
RUN --mount=type=cache,target=/var/cache/apt,id=claude-apt-cache,sharing=locked apt-get update && \
    apt-get install -y python3-dev

RUN bash -lc 'export NVM_DIR="/root/.nvm" && . "$NVM_DIR/nvm.sh" && nvm install 22 && nvm alias default 22 && ln -sf "$NVM_DIR"/versions/node/$(nvm version default)/bin/* /usr/local/bin/'

RUN npm install -g '@anthropic-ai/claude-code'
RUN npm install -g 'claude-flow@2.7.14'
RUN CLAUDE_FLOW_DIR="$(npm root -g)/claude-flow" && \
    cd "$CLAUDE_FLOW_DIR" && \
    PYTHON=/usr/local/bin/python3.11 npm rebuild better-sqlite3
RUN bash -lc 'export NVM_DIR="/root/.nvm" && . "$NVM_DIR/nvm.sh" && nvm use default >/dev/null && ln -sf "$NVM_DIR"/versions/node/$(nvm version default)/bin/* /usr/local/bin/'
RUN rm -rf /root/.npm/_npx && mkdir -p /root/.npm/_npx

RUN npm uninstall -g ruv-swarm idealTree && \
    npm install -g 'https://gitpkg.vercel.app/RyanJarv/ruv-FANN/ruv-swarm/npm?main' && \
    PYTHON=/usr/local/bin/python3.11 npm rebuild better-sqlite3 && npm rebuild ruv-swarm

# Pre-install better-sqlite3 in npx cache to ensure native bindings are built
RUN (npx --yes better-sqlite3@latest --help 2>/dev/null || true) && \
    (find /root/.npm/_npx -name 'better-sqlite3' -type d -exec sh -c 'cd {} && PYTHON=/usr/local/bin/python3.11 npm rebuild better-sqlite3 2>/dev/null || true' \; || true)

COPY claude-entrypoint.sh /usr/local/bin/claude-entrypoint.sh
RUN chmod 0755 /usr/local/bin/claude-entrypoint.sh

RUN git config --global user.email "claude@ryanjarv.sh" && \
    git config --global user.name "Ryan Gerstenkorn (claude code)"

ENTRYPOINT ["/usr/local/bin/claude-entrypoint.sh"]
