#!/usr/bin/env bash
# plaindev installer for Claude Code.
#
# Default: registers both skills globally.
#   ~/.claude/skills/plaindev/reply/SKILL.md
#   ~/.claude/skills/plaindev/check/SKILL.md
#   Claude Code auto-discovers them via description and applies when relevant.
#
# With --always-on: also injects a plaindev block into AGENTS.md and copies both skills locally.
#   ./AGENTS.md   (block fenced with <!-- plaindev-begin --> ... <!-- plaindev-end -->)
#   ./.claude/skills/plaindev/reply/SKILL.md
#   ./.claude/skills/plaindev/check/SKILL.md
#
# Flags:
#   --always-on    Make plaindev reply always active in the current repo (auto-loaded via AGENTS.md).
#   --uninstall    Remove global skills only. Does not touch this repo.
#   -h, --help     Show this help.

set -euo pipefail

REPO_URL="https://github.com/gopaz/plaindev.git"
SELF_REL="install/claude-code.sh"

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

AGENTS_SRC="$REPO_ROOT/AGENTS.md"

GLOBAL_DEST="$HOME/.claude/skills/plaindev"
LOCAL_DEST="$PWD/.claude/skills/plaindev"
REPO_AGENTS="$PWD/AGENTS.md"

ALWAYS_ON=0
UNINSTALL=0

usage() { sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --always-on) ALWAYS_ON=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "claude-code.sh: unknown flag: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ $UNINSTALL -eq 1 ]]; then
  plaindev_uninstall_global claude-code
  echo "claude-code: done."
  exit 0
fi

plaindev_verify_skills "$REPO_ROOT"

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

echo "claude-code: registering globally..."
plaindev_install_skills_to "$REPO_ROOT" "$GLOBAL_DEST"
plaindev_remove_legacy_skill_files "$GLOBAL_DEST"

if [[ $ALWAYS_ON -eq 1 ]]; then
  echo "claude-code: enabling always-on reply for this repo via AGENTS.md..."
  inject_agents_block "$REPO_AGENTS"

  echo "claude-code: installing local skills for this repo..."
  plaindev_install_skills_to "$REPO_ROOT" "$LOCAL_DEST"

  echo "claude-code: done. plaindev reply is loaded into every session in this repo."
  echo "claude-code: invoke plaindev check when reviewing a PR."
else
  echo "claude-code: done. Claude Code will apply plaindev skills when their descriptions match the task."
fi
