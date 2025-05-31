#!/bin/env zsh

# 等待 hyprpaper 启动（最多等待5秒）
max_attempts=5
attempt=1
while ! pgrep -x "hyprpaper" > /dev/null && [ $attempt -le $max_attempts ]; do
    echo "Waiting for hyprpaper to start (attempt $attempt/$max_attempts)..."
    sleep 1
    attempt=$((attempt + 1))
done

if ! pgrep -x "hyprpaper" > /dev/null; then
    echo "Error: hyprpaper is not running after $max_attempts seconds"
    exit 1
fi

# 额外等待一秒确保 hyprpaper 完全初始化
sleep 1

# 清除所有已加载的壁纸
hyprctl hyprpaper unload all 2>/dev/null || true

# 获取所有支持的图片文件
wallpapers=()
for ext in jpg jpeg png; do
    if ls $HOME/.config/backgrounds/*.$ext >/dev/null 2>&1; then
        wallpapers+=($(ls -d $HOME/.config/backgrounds/*.$ext))
    fi
done

# 检查是否找到壁纸
if [ ${#wallpapers[@]} -eq 0 ]; then
    echo "No wallpapers found in $HOME/.config/backgrounds/"
    exit 1
fi

# 随机选择壁纸
wall=${wallpapers[ $RANDOM % ${#wallpapers[@]} + 1 ]}

# 设置壁纸
if [ -f "$wall" ]; then
    echo "Setting wallpaper: $wall"
    hyprctl hyprpaper preload "$wall" || {
        echo "Failed to preload wallpaper"
        exit 1
    }
    hyprctl hyprpaper wallpaper ",$wall" || {
        echo "Failed to set wallpaper"
        exit 1
    }
    echo "Wallpaper set successfully"
else
    echo "Selected wallpaper file does not exist: $wall"
    exit 1
fi
