#!/usr/bin/env bash
# plaindev installer for Cursor.
#
# Default: registers the skill globally.
#   ~/.cursor/skills/plaindev/SKILL.md
#   Invoke with /plaindev or "use plaindev".
#
# With --always-on: also makes plaindev active automatically in the current repo.
#   ./.cursor/rules/plaindev.mdc   (alwaysApply: true)
#
# Flags:
#   --always-on    Make plaindev always active in the current repo (no /plaindev needed).
#   --uninstall    Remove installed files.
#   -h, --help     Show this help.

set -euo pipefail

REPO_URL="https://github.com/gopaz/plaindev.git"
SELF_REL="install/cursor.sh"

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

USER_DEST="$HOME/.cursor/skills/plaindev/SKILL.md"
REPO_DEST="$PWD/.cursor/rules/plaindev.mdc"

ALWAYS_ON=0
UNINSTALL=0

usage() { sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --always-on) ALWAYS_ON=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "cursor.sh: unknown flag: $1" >&2; usage; exit 1 ;;
  esac
done

[[ ! -f "$SKILL_SRC" ]] && { echo "cursor.sh: skill not found at $SKILL_SRC" >&2; exit 1; }

if [[ $UNINSTALL -eq 1 ]]; then
  echo "cursor: uninstalling..."
  [[ -e "$HOME/.cursor/skills/plaindev" ]] && rm -rf "$HOME/.cursor/skills/plaindev" && echo "  removed: $HOME/.cursor/skills/plaindev"
  [[ -e "$REPO_DEST" ]] && rm -f "$REPO_DEST" && echo "  removed: $REPO_DEST"
  echo "cursor: done."
  exit 0
fi

echo "cursor: registering globally..."
mkdir -p "$(dirname "$USER_DEST")"
cp "$SKILL_SRC" "$USER_DEST"
echo "  installed: $USER_DEST"

if [[ $ALWAYS_ON -eq 1 ]]; then
  echo "cursor: enabling always-on for this repo..."
  mkdir -p "$(dirname "$REPO_DEST")"
  {
    echo "---"
    echo "description: plaindev output style for clear, structured AI responses"
    echo "alwaysApply: true"
    echo "---"
    echo
    cat "$SKILL_SRC"
  } > "$REPO_DEST"
  echo "  installed: $REPO_DEST"
  echo "cursor: done. plaindev is now active by default in this repo."
else
  echo "cursor: done. invoke with /plaindev or 'use plaindev'."
fi
