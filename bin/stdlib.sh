# shellcheck shell=sh

repo_dir=$(CDPATH= cd "$bin_dir/.." && pwd)
submodule_dir="$repo_dir/vendor/canvas-cli"
canvas_cli_config_dir="$HOME/.canvas-cli"

instance_config_file="$repo_dir/etc/canvas-instances"
codex_config_file="$repo_dir/.codex/config.toml"

die()
{
    printf 'error: %s\n' "$*" >&2
    exit 1
}

warn()
{
    printf 'warning: %s\n' "$*" >&2
}
