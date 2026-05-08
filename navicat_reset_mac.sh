#!/bin/bash

# ==================== Navicat Premium macOS 试用重置脚本 ====================
# 功能：清除试用相关数据（类似 Windows 版删除注册表）
# 使用前请先完全退出 Navicat

echo "=== Navicat Premium macOS 试用重置脚本 ==="

# 备份重要数据建议
echo "建议先备份连接：Navicat → File → Export Connections → Export Passwords"

# 检测 Navicat 版本
APP_PATH="/Applications/Navicat Premium.app"
if [ ! -d "$APP_PATH" ]; then
    echo "错误：未在 /Applications 中找到 Navicat Premium.app"
    echo "请确认应用已安装或修改脚本中的 APP_PATH"
    exit 1
fi

VERSION=$(defaults read "$APP_PATH/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null | cut -d. -f1)
echo "检测到 Navicat Premium 版本: $VERSION"

# 根据版本确定 plist 文件
if [[ "$VERSION" == "17" || "$VERSION" == "16" ]]; then
    PLIST_FILE="$HOME/Library/Preferences/com.navicat.NavicatPremium.plist"
elif [[ "$VERSION" == "15" ]]; then
    PLIST_FILE="$HOME/Library/Preferences/com.prect.NavicatPremium15.plist"
else
    echo "未支持的版本 $VERSION，使用默认 com.navicat.NavicatPremium.plist"
    PLIST_FILE="$HOME/Library/Preferences/com.navicat.NavicatPremium.plist"
fi

# 1. 删除 plist 中的试用记录（32位哈希键）
echo "正在清理 Preferences plist..."
if [ -f "$PLIST_FILE" ]; then
    # 查找所有 32 位十六进制键并删除
    defaults read "$PLIST_FILE" 2>/dev/null | grep -oE '[0-9A-F]{32}' | while read -r key; do
        echo "删除 plist 键: $key"
        defaults delete "$PLIST_FILE" "$key" 2>/dev/null || true
    done
    # 删除整个 plist 文件（更彻底）
    rm -f "$PLIST_FILE"
    echo "已删除 plist 文件"
else
    echo "未找到 plist 文件，跳过..."
fi

# 2. 删除 Application Support 中的隐藏试用文件
APP_SUPPORT="$HOME/Library/Application Support/PremiumSoft CyberTech/Navicat CC/Navicat Premium"
if [ -d "$APP_SUPPORT" ]; then
    echo "正在清理 Application Support 中的隐藏文件..."
    find "$APP_SUPPORT" -name '.*' -type f -print0 2>/dev/null | while IFS= read -r -d '' file; do
        if [[ "$(basename "$file")" =~ ^\.[0-9A-F]{32}$ ]]; then
            echo "删除隐藏试用文件: $file"
            rm -f "$file"
        fi
    done
    echo "清理完成"
else
    echo "未找到 Application Support 目录，跳过..."
fi

# 3. 删除 Keychain 中可能的试用记录（保留用户密码）
echo "正在清理 Keychain..."
security delete-generic-password -s "com.navicat.NavicatPremium" 2>/dev/null || true
# 删除所有 32 位哈希的 Keychain 项目
security find-generic-password -a "com.navicat.NavicatPremium" 2>&1 | grep -oE '[0-9A-F]{32}' | while read -r acct; do
    echo "删除 Keychain 项目: $acct"
    security delete-generic-password -a "$acct" -s "com.navicat.NavicatPremium" 2>/dev/null || true
done

echo ""
echo "重置完成！"
echo "请重新打开 Navicat Premium，应该可以重新获得 14 天试用期。"
echo "如果仍无效，请重启 Mac 后重试，或完全卸载 Navicat 后重新安装。"

# 暂停，类似 Windows 的 pause
read -p "按任意键退出..." -n1