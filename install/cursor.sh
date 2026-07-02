#!/usr/bin/env bash
# plaindev installer for Cursor.
#
# Default: registers both skills globally.
#   ~/.cursor/skills/plaindev-reply/SKILL.md
#   ~/.cursor/skills/plaindev-check/SKILL.md
#   Invoke with /plaindev-reply, /plaindev-check, or "use plaindev".
#
# With --always-on: also enables reply in the current repo and copies both skills locally.
#   ./.cursor/rules/plaindev-reply.mdc   (alwaysApply: true)
#   ./.cursor/skills/plaindev-reply/SKILL.md
#   ./.cursor/skills/plaindev-check/SKILL.md
#
# Flags:
#   --always-on    Make plaindev reply always active in the current repo.
#   --uninstall    Remove global skills only. Does not touch this repo.
#   -h, --help     Show this help.

set -euo pipefail

REPO_URL="https://github.com/goprgo/plaindev.git"
SELF_REL="install/cursor.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-}")" 2>/dev/null && pwd)" || SCRIPT_DIR=""
if [[ -z "$SCRIPT_DIR" ]] || [[ ! -f "$SCRIPT_DIR/../skills/plaindev/reply/SKILL.md" ]]; then
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
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

REPLY_SRC="$(plaindev_skill_src "$REPO_ROOT" reply)"

GLOBAL_DEST="$HOME/.cursor/skills"
LOCAL_DEST="$PWD/.cursor/skills"
REPO_RULE="$PWD/.cursor/rules/plaindev-reply.mdc"

ALWAYS_ON=0
UNINSTALL=0

usage() { sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --always-on) ALWAYS_ON=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "cursor.sh: unknown flag: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ $UNINSTALL -eq 1 ]]; then
  plaindev_uninstall_global cursor
  echo "cursor: done."
  exit 0
fi

plaindev_verify_skills "$REPO_ROOT"

echo "cursor: registering globally..."
plaindev_remove_legacy_nested "$GLOBAL_DEST"
plaindev_install_skills_to "$REPO_ROOT" "$GLOBAL_DEST"

if [[ $ALWAYS_ON -eq 1 ]]; then
  echo "cursor: enabling always-on reply for this repo..."
  mkdir -p "$(dirname "$REPO_RULE")"
  {
    echo "---"
    echo "description: plaindev reply output style for clear, structured AI responses"
    echo "alwaysApply: true"
    echo "---"
    echo
    cat "$REPLY_SRC"
  } > "$REPO_RULE"
  echo "  installed: $REPO_RULE"

  echo "cursor: installing local skills for this repo..."
  plaindev_remove_legacy_nested "$LOCAL_DEST"
  plaindev_install_skills_to "$REPO_ROOT" "$LOCAL_DEST"

  echo "cursor: done. plaindev reply is active by default in this repo."
  echo "cursor: invoke plaindev check with /plaindev-check."
else
  echo "cursor: done. invoke with /plaindev-reply, /plaindev-check, or 'use plaindev'."
fi
