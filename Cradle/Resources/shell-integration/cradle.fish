#!/usr/bin/env fish
# Cradle terminal shell integration for fish.
# Source from your config.fish:
#     test -f ~/.config/cradle/cradle.fish; and source ~/.config/cradle/cradle.fish

set -q CRADLE_SHELL_INTEGRATION; and exit 0
set -gx CRADLE_SHELL_INTEGRATION 1

function __cradle_osc7 --on-variable PWD
    set -l host (hostname)
    printf '\e]7;file://%s%s\a' $host (string replace -a ' ' '%20' $PWD)
end

function __cradle_preexec --on-event fish_preexec
    printf '\e]133;C\a'
end

function __cradle_postexec --on-event fish_postexec
    printf '\e]133;D;%s\a' $status
end

function fish_prompt_cradle_wrap
    printf '\e]133;A\a'
    printf '%s' (fish_prompt_orig)
    printf '\e]133;B\a'
end

# Wrap fish_prompt if not already wrapped.
if not functions -q fish_prompt_orig
    functions -c fish_prompt fish_prompt_orig
    functions -e fish_prompt
    function fish_prompt
        printf '\e]133;A\a'
        fish_prompt_orig
        printf '\e]133;B\a'
    end
end

__cradle_osc7

if test "$CRADLE_COPYFILE_ENABLED" != "0"
    function copyfile
        if test (count $argv) -lt 2
            echo "usage: copyfile <local-source...> <user@host:dest>" >&2
            return 2
        end
        set -l dest $argv[-1]
        set -l sources $argv[1..-2]
        scp -r $sources $dest
    end

    function pastefile
        if test (count $argv) -lt 1
            echo "usage: pastefile <user@host:remote-source> [local-dest]" >&2
            return 2
        end
        set -l dest "."
        if test (count $argv) -ge 2
            set dest $argv[2]
        end
        scp -r $argv[1] $dest
    end
end
