FROM alpine:latest

RUN apk add --no-cache \
    nodejs npm \
    git \
    curl wget jq httpie python3 py3-pip ripgrep fd fzf coreutils gnupg ca-certificates build-base pkgconf sqlite sqlite-dev \
    bash zsh openssh-client openssl libffi-dev musl-dev py3-requests py3-yaml yq go deno

RUN git config --global user.email "codex@ryanjarv.sh" && \
    git config --global user.name "Ryan Gerstenkorn (codex)"

RUN npm install -g @openai/codex

ENTRYPOINT ["/usr/local/bin/codex"]
