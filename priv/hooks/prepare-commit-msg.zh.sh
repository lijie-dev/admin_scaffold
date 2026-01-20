#!/bin/bash
# 准备提交消息钩子，用于提醒关于署名政策

COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2

# 仅在使用编辑器时添加提醒（没有 COMMIT_SOURCE 表示使用了编辑器）
# 不添加：-m（消息）、-F（文件）、-c（重用）等情况
if [ -z "$COMMIT_SOURCE" ]; then
    # 将提醒作为注释添加到提交消息模板的顶部
    cat > "$COMMIT_MSG_FILE.new" << 'EOF'

# ⚠️  编码代理的重要提醒 ⚠️
#
# 不要在提交消息中包含 Claude Code 署名！
#
# ❌ 禁止 - 如果是自动生成的，请删除：
#    - 🤖 Generated with [Claude Code](https://claude.com/claude-code)
#    - Co-Authored-By: Claude <noreply@anthropic.com>
#
# commit-msg 钩子将拒绝包含这些署名的提交。
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 📝 提交消息指南
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#
# 格式：
#   <type>: <subject>
#
#   <body>
#
# 主题行：
#   ✓ 使用祈使语气（"Add feature" 而不是 "Added feature"）
#   ✓ 以类型前缀开头：feat:、fix:、refactor:、docs:、test:、chore:
#   ✓ 保持在 72 个字符以内
#   ✓ 不以句号结尾
#   ✓ 冒号后的首字母大写
#
# 正文：
#   ✓ 使用祈使语气（"Change" 而不是 "Changed"，"Fix" 而不是 "Fixed"）
#   ✓ 解释是什么和为什么，而不仅仅是如何做
#   ✓ 在 72 个字符处换行
#   ✓ 用空行分隔段落
#   ✓ 包含上下文：这解决了什么问题？
#   ✓ 如果适用，引用问题编号
#
# 示例：
#   feat: Add webhook retry mechanism for failed deliveries
#
#   Implement exponential backoff retry logic to handle transient
#   webhook delivery failures. This prevents data loss when downstream
#   services are temporarily unavailable.
#
#   - Add retry queue with exponential backoff (1s, 2s, 4s, 8s, 16s)
#   - Store failed attempts in webhook_audit_log
#   - Add max retry limit of 5 attempts
#
#   Resolves production issue where webhook failures caused data loss.
#
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
    cat "$COMMIT_MSG_FILE" >> "$COMMIT_MSG_FILE.new"
    mv "$COMMIT_MSG_FILE.new" "$COMMIT_MSG_FILE"
fi

exit 0
