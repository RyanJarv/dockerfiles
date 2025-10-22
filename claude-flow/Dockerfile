FROM alpine:3.19

RUN apk add --no-cache \
    nodejs \
    npm

WORKDIR /workspace

RUN npm install -g @anthropic-ai/claude-code
RUN npm install -g claude-flow@alpha

ENTRYPOINT ["/usr/local/bin/claude-flow"]
