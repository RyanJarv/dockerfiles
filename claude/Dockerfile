# syntax=docker/dockerfile:1.7-labs

FROM ryanjarv/ubuntu:latest

# Install additional build dependencies for better-sqlite3
RUN --mount=type=cache,target=/var/cache/apt,id=claude-apt-cache,sharing=locked apt-get update && \
    apt-get install -y python3-dev

RUN npm install -g '@anthropic-ai/claude-code'
RUN npm install -g 'claude-flow@alpha'

RUN npm uninstall -g ruv-swarm idealTree && \
    npm install -g 'https://gitpkg.vercel.app/RyanJarv/ruv-FANN/ruv-swarm/npm?main' && \
    PYTHON=/usr/local/bin/python3.11 npm rebuild better-sqlite3 && npm rebuild ruv-swarm

# Pre-install better-sqlite3 in npx cache to ensure native bindings are built
RUN (npx --yes better-sqlite3@latest --help 2>/dev/null || true) && \
    (find /root/.npm/_npx -name 'better-sqlite3' -type d -exec sh -c 'cd {} && PYTHON=/usr/local/bin/python3.11 npm rebuild better-sqlite3 2>/dev/null || true' \; || true)

RUN ln -f -s /root/.nvm/versions/node/v25.0.0/bin/* /usr/local/bin/

COPY claude-entrypoint.sh /usr/local/bin/claude-entrypoint.sh
RUN chmod 0755 /usr/local/bin/claude-entrypoint.sh

RUN git config --global user.email "claude@ryanjarv.sh" && \
    git config --global user.name "Ryan Gerstenkorn (claude code)"

ENTRYPOINT ["/usr/local/bin/claude-entrypoint.sh"]
