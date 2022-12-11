# Technical prelude
SHELL := bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

.PHONY: check
check:
	find . -type d \( -name 'day*' -and -not -name 'day00' \) \
		-exec echo "Running {}" \; \
		-exec ruby -C "{}" -w "solution.rb" \;
