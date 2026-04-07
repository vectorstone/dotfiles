#!/bin/bash
# 获取内置和外置硬盘温度（通过 smartctl）
# 依赖：brew install smartmontools

SMARTCTL=/opt/homebrew/bin/smartctl

get_temp() {
    local dev="$1"
    "$SMARTCTL" -A "$dev" 2>/dev/null \
        | awk '/^Temperature:/{print $2; exit}'
}

# 内置盘：disk0 的物理设备
internal=$(get_temp /dev/disk0)

# 外置盘：遍历所有 physical 磁盘，跳过内置
external_parts=""
for disk in /dev/disk[0-9] /dev/disk[1-9][0-9]; do
    [[ -b "$disk" ]] || continue
    [[ "$disk" == /dev/disk0 ]] && continue
    # 只处理 external physical 磁盘
    info=$(/usr/sbin/diskutil info "$disk" 2>/dev/null)
    echo "$info" | grep -q "Whole:\s*Yes" || continue
    echo "$info" | grep -q "Virtual:\s*Yes" && continue
    echo "$info" | grep -q "internal" && continue
    temp=$(get_temp "$disk")
    [[ -n "$temp" ]] && external_parts="${external_parts} ext:${temp}°"
done

# 组装输出
out=""
[[ -n "$internal" ]] && out="in:${internal}°"
[[ -n "$external_parts" ]] && out="${out}${external_parts}"
[[ -z "$out" ]] && out="disk:N/A"

echo "$out"
