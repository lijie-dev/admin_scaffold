#!/bin/bash
# Post-checkout hook - 切换分支时检查迁移变更

PREV_COMMIT=$1
NEW_COMMIT=$2
BRANCH_CHECKOUT=$3

# 仅在分支切换时运行（不是文件切换）
if [ "$BRANCH_CHECKOUT" = "1" ]; then
    echo "🔍 检查分支切换后的变更..."

    # 检查迁移是否变更
    if git diff --name-only $PREV_COMMIT $NEW_COMMIT | grep -q "priv/repo/migrations"; then
        echo ""
        echo "⚠️  数据库迁移已变更！"
        echo "📝 记得运行：MIX_ENV=test mix ecto.migrate"
        echo ""
    fi

    # 检查 mix.lock 是否变更
    if git diff --name-only $PREV_COMMIT $NEW_COMMIT | grep -q "mix.lock"; then
        echo ""
        echo "📦 依赖已变更（mix.lock 已更新）"
        echo "💡 考虑运行：mix deps.get"
        echo ""
    fi
fi

exit 0
