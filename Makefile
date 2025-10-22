build:
	docker build -t ryanjarv/claude -f claude/Dockerfile ./claude
	docker build -t ryanjarv/claude-flow -f claude-flow/Dockerfile ./claude-flow
	docker build -t ryanjarv/codex -f codex/Dockerfile ./codex
	docker build -t ryanjarv/gemini -f gemini/Dockerfile ./gemini

push:
	docker push ryanjarv/claude
	docker push ryanjarv/claude-flow
	docker push ryanjarv/codex
	docker push ryanjarv/gemini
