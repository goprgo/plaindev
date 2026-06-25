#!/usr/bin/env bash
# plaindev installer (convenience wrapper).
#
# Delegates to the per-tool scripts in install/. Use those directly for
# tool-by-tool control.
#
# Usage:
#   ./install.sh [tool ...] [--always-on] [--uninstall]
#
# Tools (positional): cursor, claude-code
#   If none given, runs every per-tool installer for tools detected on this machine.
#
# Flags:
#   --always-on    Pass --always-on to each per-tool installer.
#   --uninstall    Pass --uninstall to each per-tool installer.
#   -h, --help     Show this help.
#
# Examples:
#   ./install.sh                            # every detected tool, global only
#   ./install.sh --always-on                # every detected tool, also always-on for this repo
#   ./install.sh cursor                     # one tool, global only
#   ./install.sh cursor claude-code         # specific tools
#   ./install.sh cursor --always-on         # one tool, always-on for this repo
#   ./install.sh --uninstall cursor         # remove

set -euo pipefail

REPO_URL="https://github.com/gopaz/plaindev.git"
SELF_REL="install.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/skills/plaindev/reply/SKILL.md" ]]; then
  command -v git >/dev/null 2>&1 || { echo "plaindev: git is required for the remote install. install git and retry." >&2; exit 1; }
  TMP="$(mktemp -d -t plaindev.XXXXXX)"
  echo "plaindev: fetching repo into $TMP..."
  git clone --depth 1 --quiet "$REPO_URL" "$TMP" || { echo "plaindev: clone failed" >&2; rm -rf "$TMP"; exit 1; }
  bash "$TMP/$SELF_REL" "$@"
  rc=$?
  rm -rf "$TMP"
  exit $rc
fi

INSTALL_DIR="$SCRIPT_DIR/install"
KNOWN_TOOLS=(cursor claude-code)

TOOLS=()
PASSTHROUGH=()

usage() { sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

is_known_tool() {
  local t="$1"
  for k in "${KNOWN_TOOLS[@]}"; do
    [[ "$t" == "$k" ]] && return 0
  done
  return 1
}

detected() {
  case "$1" in
    cursor)      [[ -d "$HOME/.cursor" ]] ;;
    claude-code) [[ -d "$HOME/.claude" ]] || command -v claude >/dev/null 2>&1 ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --always-on|--uninstall) PASSTHROUGH+=("$1"); shift ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "install.sh: unknown flag: $1" >&2; usage; exit 1 ;;
    *)
      if is_known_tool "$1"; then
        TOOLS+=("$1"); shift
      else
        echo "install.sh: unknown tool: $1 (valid: ${KNOWN_TOOLS[*]})" >&2; exit 1
      fi ;;
  esac
done

if [[ ${#TOOLS[@]} -eq 0 ]]; then
  for t in "${KNOWN_TOOLS[@]}"; do
    detected "$t" && TOOLS+=("$t")
  done
  if [[ ${#TOOLS[@]} -eq 0 ]]; then
    echo "install.sh: no supported tools detected on this machine." >&2
    echo "  pass a tool name explicitly to force install: $0 cursor" >&2
    exit 1
  fi
fi

echo "plaindev installer"
echo "  tools: ${TOOLS[*]}"
[[ ${#PASSTHROUGH[@]} -gt 0 ]] && echo "  forwarding flags: ${PASSTHROUGH[*]}"

for tool in "${TOOLS[@]}"; do
  echo
  bash "$INSTALL_DIR/$tool.sh" "${PASSTHROUGH[@]}"
done

echo
echo "all done."
