#!/usr/bin/env bash
# Shared helpers for plaindev installers.

set -euo pipefail

PLAIN_DEV_SKILLS=(reply check)

plaindev_skills_root() {
  local repo_root="$1"
  echo "$repo_root/skills/plaindev"
}

plaindev_skill_src() {
  local repo_root="$1"
  local skill="$2"
  echo "$(plaindev_skills_root "$repo_root")/$skill/SKILL.md"
}

plaindev_verify_skills() {
  local repo_root="$1"
  local skill src
  for skill in "${PLAIN_DEV_SKILLS[@]}"; do
    src="$(plaindev_skill_src "$repo_root" "$skill")"
    [[ -f "$src" ]] || { echo "plaindev: skill not found at $src" >&2; return 1; }
  done
}

plaindev_install_skills_to() {
  local repo_root="$1"
  local dest_root="$2"
  local skill src dest
  for skill in "${PLAIN_DEV_SKILLS[@]}"; do
    src="$(plaindev_skill_src "$repo_root" "$skill")"
    dest="$dest_root/$skill/SKILL.md"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  installed: $dest"
  done
}

plaindev_remove_skill_tree() {
  local dest_root="$1"
  [[ -e "$dest_root" ]] || return 0
  rm -rf "$dest_root"
  echo "  removed: $dest_root"
}

plaindev_remove_legacy_skill_files() {
  local dest_root="$1"
  [[ -f "$dest_root/SKILL.md" ]] && rm -f "$dest_root/SKILL.md" && echo "  removed legacy: $dest_root/SKILL.md"
}

plaindev_inject_claude_md() {
  local dest="$1"
  local global_dest="$2"
  if [[ -f "$dest" ]] && grep -q "plaindev-begin" "$dest" 2>/dev/null; then
    echo "  skipped (already present): $dest"
    return
  fi
  local block
  block="$(cat <<EOF

<!-- plaindev-begin -->
## plaindev skills

Skills installed at \`~/.claude/skills/plaindev/\`. Read and apply one when the user invokes it:

- **reply** (\`$global_dest/reply/SKILL.md\`) — clear, structured output. Invoke: \`/plaindev/reply\` or "use plaindev".
- **check** (\`$global_dest/check/SKILL.md\`) — negative-only PR review. Invoke: \`/plaindev/check\` or "check this PR".
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
      plaindev_remove_legacy_skill_files "$HOME/.cursor/skills/plaindev"
      plaindev_remove_skill_tree "$HOME/.cursor/skills/plaindev"
      ;;
    claude-code)
      echo "claude-code: removing global plaindev..."
      plaindev_remove_legacy_skill_files "$HOME/.claude/skills/plaindev"
      plaindev_remove_skill_tree "$HOME/.claude/skills/plaindev"
      ;;
    *)
      echo "plaindev: unknown tool: $tool (valid: cursor, claude-code)" >&2
      return 1
      ;;
  esac
}
