#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

##==================================================================================================
##	DEPENDENCY CHECKS
##==================================================================================================

requireCommand() { command -v "$1" >/dev/null 2>&1 || { printf "Abort: '%s' not found\n" "$1" >&2; exit 1; }; }

requireCommand bash
requireCommand mkdir

##==================================================================================================
##	GLOBALS
##==================================================================================================

declare -r SCRIPT_NAME="${0##*/}"
declare SCRIPT_DIR
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
declare -r SCRIPT_DIR

# shellcheck source=test/support/testlib.sh
source "$SCRIPT_DIR/support/testlib.sh"

##==================================================================================================
##	CORE FUNCTIONS
##==================================================================================================

runInstallerTest() {
    local test_root
    local output_script
    local output_config_dir

    test_root="$(createTestRoot install)"
    output_script="$test_root/install/synth-shell-greeter.sh"
    output_config_dir="$test_root/install"
    export HOME="$test_root/home"
    mkdir -p "$HOME"
    : > "$HOME/.bashrc"

    bash "$PROJECT_ROOT/setup.sh" "$output_script" "$output_config_dir"

    assertFile "$output_script"
    assertFile "$output_config_dir/synth-shell-greeter.config"
    bash -n "$output_script"
    TERM=dumb bash --noprofile --norc -c 'source "$1"' bash "$output_script"

    printf 'PASS: isolated install: %s\n' "$test_root"
}

##==================================================================================================
##	ARGUMENT PARSING
##==================================================================================================

[[ $# -eq 0 ]] || { printf '%s: no arguments expected\n' "$SCRIPT_NAME" >&2; exit 1; }

##==================================================================================================
##	MAIN
##==================================================================================================

main() {
    runInstallerTest
}

##==================================================================================================
##	SCRIPT ENTRY POINT
##==================================================================================================

main
