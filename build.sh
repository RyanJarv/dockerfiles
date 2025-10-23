#!/usr/bin/env bash

docker buildx build -t ryanjarv/ubuntu-base -f ubuntu-base/Dockerfile ./ubuntu-base &
docker buildx build -t ryanjarv/ubuntu -f ubuntu/Dockerfile ./ubuntu &
docker buildx build -t ryanjarv/net -f net/Dockerfile ./net &
docker buildx build -t ryanjarv/claude -f claude/Dockerfile ./claude &
docker buildx build -t ryanjarv/net -f net/Dockerfile ./net &
docker buildx build -t ryanjarv/codex -f codex/Dockerfile ./codex &
docker buildx build -t ryanjarv/gemini -f gemini/Dockerfile ./gemini &
docker buildx build -t ryanjarv/ruv-swarm -f ruv-swarm/Dockerfile ./ruv-swarm &

wait
