#!/usr/bin/env bash
# plaindev global uninstaller.
#
# Removes global plaindev skills only. Does not touch repo-local files.
# To remove local installs, delete these yourself:
#   .cursor/skills/plaindev-reply/, .cursor/skills/plaindev-check/, .cursor/skills/plaindev-task/
#   .cursor/rules/plaindev-reply.mdc
#   .claude/skills/plaindev-reply/, .claude/skills/plaindev-check/, .claude/skills/plaindev-task/
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

# Remove flat skills (plaindev-reply, plaindev-check) plus the old nested
# layout (plaindev/) left by earlier versions, under a skills parent dir.
plaindev_remove_from() {
  local skills_parent="$1"
  plaindev_remove_tree "$skills_parent/plaindev-reply"
  plaindev_remove_tree "$skills_parent/plaindev-check"
  plaindev_remove_tree "$skills_parent/plaindev-task"
  [[ -e "$skills_parent/plaindev" ]] && plaindev_remove_tree "$skills_parent/plaindev"
  return 0
}

# Remove the plaindev block from a CLAUDE.md, if present.
plaindev_remove_claude_md_block() {
  local dest="$1"
  [[ -f "$dest" ]] || return 0
  grep -q "plaindev-begin" "$dest" 2>/dev/null || return 0
  local tmp
  tmp="$(mktemp)"
  awk '/<!-- plaindev-begin -->/{skip=1} !skip{print} /<!-- plaindev-end -->/{skip=0}' "$dest" > "$tmp"
  mv "$tmp" "$dest"
  echo "  removed block: $dest"
}

plaindev_uninstall_global() {
  local tool="$1"
  case "$tool" in
    cursor)
      echo "cursor: removing global plaindev..."
      plaindev_remove_from "$HOME/.cursor/skills"
      ;;
    claude-code)
      echo "claude-code: removing global plaindev..."
      plaindev_remove_from "$HOME/.claude/skills"
      plaindev_remove_claude_md_block "$HOME/.claude/CLAUDE.md"
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
