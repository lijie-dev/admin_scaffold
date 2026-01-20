#!/bin/bash
# Post-merge hook - 检查迁移变更

echo "🔍 检查合并后的变更..."

# 检查迁移是否改变
if git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD | grep -q "priv/repo/migrations"; then
    echo ""
    echo "⚠️  数据库迁移已改变！"
    echo "📝 记住运行: MIX_ENV=test mix ecto.migrate"
    echo ""
fi

# 检查 mix.lock 是否改变
if git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD | grep -q "mix.lock"; then
    echo ""
    echo "📦 依赖已改变 (mix.lock 已更新)"
    echo "💡 考虑运行: mix deps.get"
    echo ""
fi

exit 0
