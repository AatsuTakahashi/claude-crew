#!/bin/bash
# setup.sh — Claude Crewを対象プロジェクトにセットアップ
#
# Usage:
#   bash /path/to/claude-crew/scripts/setup.sh /path/to/target-project
#
# これにより対象プロジェクトの .claude/ にCrew設定がシンボリックリンクされる

set -euo pipefail

CREW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_DIR="${1:?Usage: $0 <target-project-dir>}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "ERROR: $TARGET_DIR does not exist" >&2
  exit 1
fi

echo "=== Claude Crew Setup ==="
echo "Crew:   $CREW_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Create .claude directory if needed
mkdir -p "$TARGET_DIR/.claude"

# Symlink agent definitions
if [[ ! -L "$TARGET_DIR/.claude/agents" ]]; then
  ln -sf "$CREW_DIR/agents" "$TARGET_DIR/.claude/agents"
  echo "✓ Linked agents/ → .claude/agents"
else
  echo "• agents/ already linked"
fi

# Create project-specific memory dirs
mkdir -p "$TARGET_DIR/.claude/crew-memory/"{architect,coder,reviewer,researcher}
echo "✓ Created .claude/crew-memory/ directories"

# Copy crew config (not symlink — project can customize)
if [[ ! -f "$TARGET_DIR/.claude/crew.yaml" ]]; then
  cp "$CREW_DIR/config/crew.yaml" "$TARGET_DIR/.claude/crew.yaml"
  echo "✓ Copied crew.yaml to .claude/"
else
  echo "• crew.yaml already exists"
fi

# Append crew instructions to CLAUDE.md if not already present
if [[ -f "$TARGET_DIR/CLAUDE.md" ]]; then
  if ! grep -q "Claude Crew" "$TARGET_DIR/CLAUDE.md" 2>/dev/null; then
    echo "" >> "$TARGET_DIR/CLAUDE.md"
    echo "# Claude Crew Integration" >> "$TARGET_DIR/CLAUDE.md"
    echo "" >> "$TARGET_DIR/CLAUDE.md"
    echo "This project uses Claude Crew for role-specialized agents." >> "$TARGET_DIR/CLAUDE.md"
    echo "Agent definitions: .claude/agents/" >> "$TARGET_DIR/CLAUDE.md"
    echo "Agent memory: .claude/crew-memory/" >> "$TARGET_DIR/CLAUDE.md"
    echo "Crew config: .claude/crew.yaml" >> "$TARGET_DIR/CLAUDE.md"
    echo "✓ Added Crew section to CLAUDE.md"
  else
    echo "• CLAUDE.md already has Crew section"
  fi
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Usage: Start Claude Code in $TARGET_DIR"
echo "The Orchestrator will automatically use specialized agents."
