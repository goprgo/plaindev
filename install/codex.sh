#!/usr/bin/env bash
# plaindev installer for Codex.
#
# Default: registers the skill globally.
#   ~/.codex/skills/plaindev/SKILL.md
#   Codex auto-discovers it via description and applies when relevant.
#
# With --always-on: also injects a plaindev block into AGENTS.md in the current repo.
#   ./AGENTS.md   (block fenced with <!-- plaindev-begin --> ... <!-- plaindev-end -->)
#   Codex reads AGENTS.md into every conversation, so plaindev is active by default.
#
# Flags:
#   --always-on    Make plaindev always active in the current repo (auto-loaded via AGENTS.md).
#   --uninstall    Remove installed files and (if --always-on) strip the AGENTS.md block.
#   -h, --help     Show this help.

set -euo pipefail

REPO_URL="https://github.com/gopaz/plaindev.git"
SELF_REL="install/codex.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/../skills/plaindev/SKILL.md" ]]; then
  command -v git >/dev/null 2>&1 || { echo "plaindev: git is required for the remote install. install git and retry." >&2; exit 1; }
  TMP="$(mktemp -d -t plaindev.XXXXXX)"
  echo "plaindev: fetching repo into $TMP..."
  git clone --depth 1 --quiet "$REPO_URL" "$TMP" || { echo "plaindev: clone failed" >&2; rm -rf "$TMP"; exit 1; }
  bash "$TMP/$SELF_REL" "$@"
  rc=$?
  rm -rf "$TMP"
  exit $rc
fi

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_SRC="$REPO_ROOT/skills/plaindev/SKILL.md"
AGENTS_SRC="$REPO_ROOT/AGENTS.md"

USER_DEST="$HOME/.codex/skills/plaindev/SKILL.md"
REPO_AGENTS="$PWD/AGENTS.md"

ALWAYS_ON=0
UNINSTALL=0

usage() { sed -n '2,16p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --always-on) ALWAYS_ON=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "codex.sh: unknown flag: $1" >&2; usage; exit 1 ;;
  esac
done

[[ ! -f "$SKILL_SRC" ]] && { echo "codex.sh: skill not found at $SKILL_SRC" >&2; exit 1; }

inject_agents_block() {
  local dest="$1"
  if [[ -f "$dest" ]] && grep -q "plaindev-begin" "$dest" 2>/dev/null; then
    echo "  skipped (already present): $dest"
    return
  fi
  {
    [[ -f "$dest" ]] && cat "$dest" && echo
    echo "<!-- plaindev-begin -->"
    cat "$AGENTS_SRC"
    echo "<!-- plaindev-end -->"
  } > "$dest.tmp"
  mv "$dest.tmp" "$dest"
  echo "  installed: $dest"
}

strip_agents_block() {
  local dest="$1"
  [[ ! -f "$dest" ]] && return
  awk '
    /<!-- plaindev-begin -->/ { skip=1; next }
    /<!-- plaindev-end -->/   { skip=0; next }
    !skip { print }
  ' "$dest" > "$dest.tmp"
  mv "$dest.tmp" "$dest"
  echo "  cleaned: $dest"
}

if [[ $UNINSTALL -eq 1 ]]; then
  echo "codex: uninstalling..."
  [[ -e "$HOME/.codex/skills/plaindev" ]] && rm -rf "$HOME/.codex/skills/plaindev" && echo "  removed: $HOME/.codex/skills/plaindev"
  [[ -f "$REPO_AGENTS" ]] && grep -q "plaindev-begin" "$REPO_AGENTS" 2>/dev/null && strip_agents_block "$REPO_AGENTS"
  echo "codex: done."
  exit 0
fi

echo "codex: registering globally..."
mkdir -p "$(dirname "$USER_DEST")"
cp "$SKILL_SRC" "$USER_DEST"
echo "  installed: $USER_DEST"

if [[ $ALWAYS_ON -eq 1 ]]; then
  echo "codex: enabling always-on for this repo via AGENTS.md..."
  inject_agents_block "$REPO_AGENTS"
  echo "codex: done. plaindev is now loaded into every session in this repo."
else
  echo "codex: done. Codex will apply plaindev when its description matches the task."
fi
