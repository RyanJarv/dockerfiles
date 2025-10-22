FROM alpine:latest

RUN apk add --no-cache \
    nodejs \
    npm \
    git

RUN git config --global user.email "codex@ryanjarv.sh" && \
    git config --global user.name "Ryan Gerstenkorn (codex)"

WORKDIR /workspace

RUN npm install -g @openai/codex

ENTRYPOINT ["/usr/local/bin/codex"]
