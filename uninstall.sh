#!/usr/bin/env bash
# plaindev global uninstaller.
#
# Removes global plaindev skills only. Does not touch repo-local files.
# To remove local installs, delete these yourself:
#   .cursor/skills/plaindev/
#   .cursor/rules/plaindev-reply.mdc
#   .claude/skills/plaindev/
#   AGENTS.md plaindev block (between <!-- plaindev-begin --> and <!-- plaindev-end -->)
#
# Usage:
#   ./uninstall.sh [tool ...]
#
# Tools (positional): cursor, claude-code
#   If none given, uninstalls from every tool listed above.
#
# Flags:
#   -h, --help     Show this help.
#
# Examples:
#   ./uninstall.sh                  # remove global plaindev from cursor and claude-code
#   ./uninstall.sh cursor           # cursor only
#   curl -fsSL .../uninstall.sh | bash

set -euo pipefail

KNOWN_TOOLS=(cursor claude-code)
TOOLS=()

usage() { sed -n '2,23p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

is_known_tool() {
  local t="$1"
  for k in "${KNOWN_TOOLS[@]}"; do
    [[ "$t" == "$k" ]] && return 0
  done
  return 1
}

plaindev_remove_tree() {
  local dest="$1"
  if [[ -e "$dest" ]]; then
    rm -rf "$dest"
    echo "  removed: $dest"
  else
    echo "  skipped (not found): $dest"
  fi
}

plaindev_remove_legacy_file() {
  local dest="$1"
  if [[ -f "$dest" ]]; then
    rm -f "$dest"
    echo "  removed legacy: $dest"
  fi
}

plaindev_uninstall_global() {
  local tool="$1"
  case "$tool" in
    cursor)
      echo "cursor: removing global plaindev..."
      plaindev_remove_legacy_file "$HOME/.cursor/skills/plaindev/SKILL.md"
      plaindev_remove_tree "$HOME/.cursor/skills/plaindev"
      ;;
    claude-code)
      echo "claude-code: removing global plaindev..."
      plaindev_remove_legacy_file "$HOME/.claude/skills/plaindev/SKILL.md"
      plaindev_remove_tree "$HOME/.claude/skills/plaindev"
      ;;
    *)
      echo "plaindev: unknown tool: $tool (valid: cursor, claude-code)" >&2
      return 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --*) echo "uninstall.sh: unknown flag: $1" >&2; usage; exit 1 ;;
    *)
      if is_known_tool "$1"; then
        TOOLS+=("$1"); shift
      else
        echo "uninstall.sh: unknown tool: $1 (valid: ${KNOWN_TOOLS[*]})" >&2; exit 1
      fi ;;
  esac
done

if [[ ${#TOOLS[@]} -eq 0 ]]; then
  TOOLS=("${KNOWN_TOOLS[@]}")
fi

echo "plaindev uninstall (global only)"
echo "  tools: ${TOOLS[*]}"

for tool in "${TOOLS[@]}"; do
  echo
  plaindev_uninstall_global "$tool"
done

echo
echo "all done."
