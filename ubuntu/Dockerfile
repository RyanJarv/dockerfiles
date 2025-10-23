# syntax=docker/dockerfile:1.7-labs

FROM ryanjarv/ubuntu-base:latest

RUN --mount=type=cache,target=/var/cache/apt,id=claude-apt-cache,sharing=locked apt-get install -y gnupg ca-certificates curl wget
RUN --mount=type=cache,target=/var/cache/apt,id=claude-apt-cache,sharing=locked apt-get install -y git vim bash
RUN --mount=type=cache,target=/var/cache/apt,id=claude-apt-cache,sharing=locked apt-get install -y yq jq ripgrep fd-find fzf 
RUN --mount=type=cache,target=/var/cache/apt,id=claude-apt-cache,sharing=locked apt-get install -y coreutils pkg-config binutils
RUN --mount=type=cache,target=/var/cache/apt,id=claude-apt-cache,sharing=locked apt-get install -y libffi-dev musl-dev openssl

ENTRYPOINT ["bash", "-c"]
