# dotfiles

这个仓库使用 GNU Stow 管理。每个顶层目录都对应 `$HOME` 下的一个配置包。

## Ghostty

Ghostty 现在拆成了共享配置和 macOS 覆盖配置：

- 共享配置：`ghostty/.config/ghostty/config`
- macOS 覆盖：`ghosttyMac/Library/Application Support/com.mitchellh.ghostty/config`

安装时建议：

- Linux：`stow ghostty`
- macOS：`stow ghostty ghosttyMac`

Ghostty 会先加载 XDG 配置，再在 macOS 上额外加载 `~/Library/Application Support/com.mitchellh.ghostty/config`，因此 macOS 文件会覆盖共享配置中的同名项。

修改配置后，可以在 Ghostty 里重载配置：

- Linux: `Ctrl + Shift + ,`
- macOS: `Cmd + Shift + ,`

注意：并不是所有配置项都能热重载，有些只会在新开的终端里生效；例如背景透明度相关配置在 macOS 上通常需要完全重启 Ghostty 才会生效。

## 后续可补充

- `.zshrc`
- `.codex`
- 其他应用配置
