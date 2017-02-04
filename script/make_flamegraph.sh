#!/bin/bash

# Makes a flame graph from :eflame's output. Could eventually be converted to
# Elixir, but would require I/O redirection.

STACK_TO_FLAME="./deps/eflame/stack_to_flame.sh"
STACK_FILE="$1"
SVG_OUT_FILE="${STACK_FILE/%.out/.svg}"

"$STACK_TO_FLAME" < "$STACK_FILE" > "$SVG_OUT_FILE"
