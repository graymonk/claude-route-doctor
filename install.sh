#!/usr/bin/env bash
# ============================================================
# claude-route-doctor 一键安装脚本
#
# 在线安装（推荐）：
#   curl -fsSL https://raw.githubusercontent.com/graymonk/claude-route-doctor/main/install.sh | bash
#
# 本地安装（克隆仓库后）：
#   ./install.sh
#
# 可选参数：
#   --claude     同时安装一份到 ~/.claude/skills（Claude Code）
#   --dir PATH   额外安装到指定技能目录（其他智能体，如 workbuddy）
#   -h           显示帮助
# ============================================================
set -euo pipefail

SKILL_NAME="claude-route-doctor"
REPO="graymonk/claude-route-doctor"
BRANCH="main"
AGENT_DEFAULT="$HOME/.agents/skills"   # ZCode 等智能体的通用标准位置
AGENT_CLAUDE="$HOME/.claude/skills"    # Claude Code
EXTRA_DIR=""
INSTALL_CLAUDE=0

print_help() {
  cat <<'HELP'
claude-route-doctor 一键安装脚本

用法:
  curl -fsSL https://raw.githubusercontent.com/graymonk/claude-route-doctor/main/install.sh | bash
  ./install.sh [--claude] [--dir PATH]

参数:
  --claude     同时安装到 ~/.claude/skills（Claude Code）
  --dir PATH   额外安装到指定技能目录（其他智能体，如 workbuddy）
  -h, --help   显示本帮助
HELP
}

while [ $# -gt 0 ]; do
  case "$1" in
    --claude) INSTALL_CLAUDE=1 ;;
    --dir)
      shift
      EXTRA_DIR="${1:-}"
      [ -n "$EXTRA_DIR" ] || { echo "错误: --dir 需要一个路径"; exit 1; }
      ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "未知参数: $1（用 -h 查看帮助）"; exit 1 ;;
  esac
  shift
done

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 优先使用脚本旁的本地副本（克隆仓库后运行），否则从 GitHub 下载
SRC=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/SKILL.md" ] && [ -d "$SCRIPT_DIR/references" ]; then
  SRC="$SCRIPT_DIR"
else
  echo "==> 从 GitHub 下载 $REPO ..."
  curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" -o "$TMP/repo.tar.gz"
  tar -xzf "$TMP/repo.tar.gz" -C "$TMP"
  SRC="$TMP/$REPO-$BRANCH"
fi

install_to() {
  _dest_base="$1"
  _dest="$_dest_base/$SKILL_NAME"
  mkdir -p "$_dest_base"
  if [ -d "$_dest" ]; then
    mv "$_dest" "$_dest.bak-$(date +%Y%m%d%H%M%S)"
    echo "    （发现旧版本，已备份为 .bak-*）"
  fi
  cp -R "$SRC" "$_dest"
  echo "    已安装: $_dest"
}

echo "==> 安装 $SKILL_NAME"
install_to "$AGENT_DEFAULT"

if [ "$INSTALL_CLAUDE" = "1" ]; then
  install_to "$AGENT_CLAUDE"
fi

if [ -n "$EXTRA_DIR" ]; then
  install_to "$EXTRA_DIR"
fi

cat <<'TIP'

完成！请重启一次 AI 工具（新开会话），然后直接说人话触发，例如：
  "我的 Claude 检测页信任分从 97 掉到 79 了，帮我修一下"
  "检测页 DNS 显示中国 DNS，泄露了，怎么办"

支持范围: 仅 Clash Verge Rev (Mac/Windows)
检测页:   https://ip.net.coffee/claude/
TIP
