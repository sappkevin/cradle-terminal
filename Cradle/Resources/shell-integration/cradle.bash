#!/usr/bin/env bash
# Cradle terminal shell integration for bash.
# Source from your ~/.bashrc:
#     [[ -f ~/.config/cradle/cradle.bash ]] && source ~/.config/cradle/cradle.bash

[[ -n "${CRADLE_SHELL_INTEGRATION:-}" ]] && return
export CRADLE_SHELL_INTEGRATION=1

__cradle_osc7() {
    local host="${HOSTNAME:-$(hostname)}"
    printf '\e]7;file://%s%s\a' "$host" "${PWD// /%20}"
}

__cradle_preexec() { printf '\e]133;C\a'; }
__cradle_precmd_done() {
    local exit=$?
    printf '\e]133;D;%s\a' "$exit"
    __cradle_osc7
}

# Bash doesn't have native preexec; use DEBUG trap with a guard.
__cradle_in_command=0
__cradle_debug_trap() {
    if [[ $__cradle_in_command -eq 0 && -n "$BASH_COMMAND" && "$BASH_COMMAND" != "$PROMPT_COMMAND" ]]; then
        __cradle_in_command=1
        __cradle_preexec
    fi
}
trap '__cradle_debug_trap' DEBUG

PROMPT_COMMAND="__cradle_precmd_done; __cradle_in_command=0; ${PROMPT_COMMAND:-}"

# Mark prompt start/end inline. \[ \] tell bash these are non-printing.
PS1='\[\e]133;A\a\]'"$PS1"'\[\e]133;B\a\]'

if [[ "${CRADLE_COPYFILE_ENABLED:-1}" == "1" ]]; then
    copyfile() {
        if [[ $# -lt 2 ]]; then
            echo "usage: copyfile <local-source...> <user@host:dest>" >&2
            return 2
        fi
        local dest="${!#}"
        local sources=("${@:1:$#-1}")
        scp -r "${sources[@]}" "$dest"
    }
    pastefile() {
        if [[ $# -lt 1 ]]; then
            echo "usage: pastefile <user@host:remote-source> [local-dest]" >&2
            return 2
        fi
        scp -r "$1" "${2:-.}"
    }
fi
