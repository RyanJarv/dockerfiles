FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
 && rm -rf /var/lib/apt/lists/*

# Install Node.js from NodeSource so we match the versions Claude Flow expects
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
 && apt-get update && apt-get install -y nodejs \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

RUN npm install -g @anthropic-ai/claude-code
RUN npm install -g claude-flow@alpha

ENTRYPOINT ["/usr/bin/claude-flow"]
