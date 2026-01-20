#!/bin/bash
# Pre-commit 钩子用于强制执行质量检查

# 检查是否被绕过（效果有限但增加了摩擦力）
if [ -n "$GIT_COMMIT_NO_VERIFY" ]; then
    echo "❌ 错误：检测到 Pre-commit 绕过"
    echo "不允许绕过 pre-commit 钩子"
    echo "请修复问题，而不是绕过检查"
    exit 1
fi

echo "🔍 运行 pre-commit 质量检查..."
echo "================================================"

# 加载 asdf 以确保 mix 可用
if [ -f "/usr/local/opt/asdf/libexec/asdf.sh" ]; then
  source /usr/local/opt/asdf/libexec/asdf.sh
elif [ -f "$HOME/.asdf/asdf.sh" ]; then
  source "$HOME/.asdf/asdf.sh"
fi

cd "$(git rev-parse --show-toplevel)"

# 在运行 precommit 之前捕获暂存文件列表
STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

if ! mix precommit; then
    echo "❌ Pre-commit 检查失败！"
    exit 1
fi

# 重新暂存由 mix format（或其他 precommit 任务）修改的文件
UNSTAGED_FILES=$(git diff --name-only)
MODIFIED_STAGED_FILES=""

for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        # 检查此暂存文件现在是否有未暂存的更改（使用 grep -F 进行字面匹配）
        if echo "$UNSTAGED_FILES" | grep -Fxq "$file"; then
            MODIFIED_STAGED_FILES="$MODIFIED_STAGED_FILES $file"
        fi
    fi
done

# 自动重新添加格式化的文件
if [ -n "$MODIFIED_STAGED_FILES" ]; then
    echo ""
    echo "📝 重新暂存由 mix format 修改的文件："
    echo "$MODIFIED_STAGED_FILES" | tr ' ' '\n' | grep -v '^$'
    git add $MODIFIED_STAGED_FILES
    echo "✅ 格式化的文件已重新暂存"
fi

echo "✅ 所有 pre-commit 检查已通过！"
exit 0
