#!/usr/bin/env bash
# Shared helpers for plaindev installers.
#
# Skills install FLAT, one directory level, to match the Agent Skills / Claude
# Code convention: <skills>/<skill-name>/SKILL.md. The command name is the
# directory name, so these install as plaindev-reply and plaindev-check and are
# invoked with /plaindev-reply and /plaindev-check.

set -euo pipefail

PLAIN_DEV_SKILLS=(reply check task)

plaindev_skill_src() {
  local repo_root="$1"
  local skill="$2"
  echo "$repo_root/skills/plaindev/$skill/SKILL.md"
}

plaindev_installed_name() {
  echo "plaindev-$1"
}

plaindev_verify_skills() {
  local repo_root="$1"
  local skill src
  for skill in "${PLAIN_DEV_SKILLS[@]}"; do
    src="$(plaindev_skill_src "$repo_root" "$skill")"
    [[ -f "$src" ]] || { echo "plaindev: skill not found at $src" >&2; return 1; }
  done
}

# Install each skill flat under a skills parent dir as plaindev-<skill>/SKILL.md.
plaindev_install_skills_to() {
  local repo_root="$1"
  local skills_parent="$2"
  local skill src dest
  for skill in "${PLAIN_DEV_SKILLS[@]}"; do
    src="$(plaindev_skill_src "$repo_root" "$skill")"
    dest="$skills_parent/$(plaindev_installed_name "$skill")/SKILL.md"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  installed: $dest"
  done
}

# Remove the old nested layout (~/.<tool>/skills/plaindev/) left by earlier
# versions. Safe to call before a fresh install.
plaindev_remove_legacy_nested() {
  local skills_parent="$1"
  if [[ -e "$skills_parent/plaindev" ]]; then
    rm -rf "$skills_parent/plaindev"
    echo "  removed legacy: $skills_parent/plaindev"
  fi
}

# Remove installed flat skills plus any legacy nested layout.
plaindev_remove_installed_skills() {
  local skills_parent="$1"
  local skill dir
  for skill in "${PLAIN_DEV_SKILLS[@]}"; do
    dir="$skills_parent/$(plaindev_installed_name "$skill")"
    if [[ -e "$dir" ]]; then
      rm -rf "$dir"
      echo "  removed: $dir"
    fi
  done
  plaindev_remove_legacy_nested "$skills_parent"
}

plaindev_inject_claude_md() {
  local dest="$1"
  local skills_parent="$2"
  # Refresh: drop any existing block first so re-runs pick up path/command changes.
  if [[ -f "$dest" ]] && grep -q "plaindev-begin" "$dest" 2>/dev/null; then
    plaindev_remove_claude_md_block "$dest"
  fi
  local block
  block="$(cat <<EOF

<!-- plaindev-begin -->
## plaindev skills

Skills installed at \`$skills_parent/\`. Read and apply one when the user invokes it:

- **plaindev-reply** (\`$skills_parent/plaindev-reply/SKILL.md\`) — clear, structured output. Invoke: \`/plaindev-reply\` or "use plaindev".
- **plaindev-check** (\`$skills_parent/plaindev-check/SKILL.md\`) — negative-only PR review. Invoke: \`/plaindev-check\` or "check this PR".
- **plaindev-task** (\`$skills_parent/plaindev-task/SKILL.md\`) — ticket → branch → PR workflow (Jira + gh). Invoke: \`/plaindev-task\` or "run the task workflow".
<!-- plaindev-end -->
EOF
)"
  printf '%s\n' "$block" >> "$dest"
  echo "  registered: $dest"
}

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
      plaindev_remove_installed_skills "$HOME/.cursor/skills"
      ;;
    claude-code)
      echo "claude-code: removing global plaindev..."
      plaindev_remove_installed_skills "$HOME/.claude/skills"
      ;;
    *)
      echo "plaindev: unknown tool: $tool (valid: cursor, claude-code)" >&2
      return 1
      ;;
  esac
}
