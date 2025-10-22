#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [[ -e ~/.bashrc ]]; then
	echo "source $SCRIPT_DIR/sh_functions"  >> ~/.bashrc
fi

if [[ -e ~/.zshrc ]]; then
	echo "source $SCRIPT_DIR/sh_functions"  >> ~/.zshrc
fi
