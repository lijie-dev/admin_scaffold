#!/bin/bash
# 提交消息钩子，用于阻止 Claude Code 署名

COMMIT_MSG_FILE=$1

# 检查提交消息中是否包含 Claude Code 署名（忽略以 # 开头的注释行）
if grep -v '^#' "$COMMIT_MSG_FILE" | grep -q "Co-Authored-By: Claude" || \
   grep -v '^#' "$COMMIT_MSG_FILE" | grep -q "Generated with.*Claude Code"; then
    echo "❌ 提交消息包含 Claude Code 署名！"
    echo "请从提交消息中删除以下行："
    echo "  - 🤖 Generated with [Claude Code](https://claude.com/claude-code)"
    echo "  - Co-Authored-By: Claude <noreply@anthropic.com>"
    exit 1
fi

exit 0
