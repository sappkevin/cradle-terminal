#!/usr/bin/env zsh
# Cradle terminal shell integration for zsh.
# Emits OSC 133 prompt marks and OSC 7 cwd updates so the Cradle app
# can track command boundaries, exit codes, and current directory.
#
# Source from your ~/.zshrc:
#     [[ -f ~/.config/cradle/cradle.zsh ]] && source ~/.config/cradle/cradle.zsh

# Don't double-source.
[[ -n "${CRADLE_SHELL_INTEGRATION:-}" ]] && return
export CRADLE_SHELL_INTEGRATION=1

# OSC 133 markers
__cradle_prompt_start() { printf '\e]133;A\a' }
__cradle_prompt_end()   { printf '\e]133;B\a' }
__cradle_preexec()      { printf '\e]133;C\a' }
__cradle_precmd_done() {
    local exit=$?
    printf '\e]133;D;%s\a' "$exit"
}

# OSC 7 cwd update
__cradle_osc7() {
    local host="${HOST:-$(hostname)}"
    printf '\e]7;file://%s%s\a' "$host" "${PWD// /%20}"
}

# Wire into precmd/preexec
autoload -Uz add-zsh-hook
add-zsh-hook precmd __cradle_precmd_done
add-zsh-hook precmd __cradle_osc7
add-zsh-hook preexec __cradle_preexec

# Wrap PS1 with prompt-start / prompt-end marks
PS1=$'%{\e]133;A\a%}'$PS1$'%{\e]133;B\a%}'

# Inline autosuggestions (fish-style ghost text). Bundled by Cradle if enabled.
if [[ -n "${CRADLE_INTELLISENSE_ENABLED:-1}" ]]; then
    if [[ -f "${CRADLE_RESOURCES:-}/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
        source "${CRADLE_RESOURCES}/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi
fi

# copyfile / pastefile helpers (wrap scp). Disabled by setting CRADLE_COPYFILE_ENABLED=0.
if [[ "${CRADLE_COPYFILE_ENABLED:-1}" == "1" ]]; then
    copyfile() {
        if [[ $# -lt 2 ]]; then
            echo "usage: copyfile <local-source...> <user@host:dest>" >&2
            return 2
        fi
        # Last arg is the destination; everything before is source(s). Globs
        # expand naturally before we get here.
        local dest="${@: -1}"
        local sources=("${@:1:$#-1}")
        scp -r "${sources[@]}" "$dest"
    }

    pastefile() {
        if [[ $# -lt 1 ]]; then
            echo "usage: pastefile <user@host:remote-source> [local-dest]" >&2
            return 2
        fi
        local src="$1"
        local dest="${2:-.}"
        scp -r "$src" "$dest"
    }
fi
