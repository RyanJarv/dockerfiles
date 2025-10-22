FROM alpine:3.19

RUN apk add --no-cache \
    nodejs \
    npm

WORKDIR /workspace

RUN npm install -g @openai/codex

ENTRYPOINT ["/usr/local/bin/codex"]
