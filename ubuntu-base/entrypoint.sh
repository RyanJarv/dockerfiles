#!/usr/bin/env sh

if test -f ./.venv/bin/activate; then
    . .venv/bin/activate
fi

"${@}"
