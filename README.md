# macOS 窗口贴靠与最大化快捷键

一个独立的 [Hammerspoon](https://www.hammerspoon.org/) 模块，用 `Control + Option + 方向键` 调整当前窗口在当前显示器中所占的区域。

用 `Command + Option + Shift + ← / →` 将窗口移动到上一个／下一个显示器。

外接键盘通常将 Option 标为 Alt。这组快捷键无需 Fn，也不占用常见的 `Command + 方向键` 文本导航组合。

## 快捷键

| 快捷键 | 行为 |
| --- | --- |
| `Control + Option + ←` | 左半屏 |
| `Control + Option + →` | 右半屏 |
| `Control + Option + ↑` | 上半屏；处于上半屏时再按，最大化到当前显示器 |
| `Control + Option + ↓` | 下半屏 |
| `Command + Option + Shift + ←` | 移到上一个显示器 |
| `Command + Option + Shift + →` | 移到下一个显示器 |

最大化后再次按上箭头，保持最大化。这里的最大化使用显示器的可用桌面区域，保留菜单栏和 Dock。

上箭头按**实际窗口区域**判断状态，无需快速连按。窗口先被手动放到上半屏，再按上箭头，同样会最大化。窗口移动到另一台显示器后，以该显示器的可用区域判断。

跨显示器移动保留窗口的相对位置和尺寸比例，例如左半屏移过去后仍占目标显示器的左半屏。显示器尺寸不同，窗口的绝对尺寸会随之调整。上一个／下一个按照 [Hammerspoon 的显示器顺序](https://www.hammerspoon.org/docs/hs.screen.html#next) 循环选择，不代表桌面排列中的物理左右；只有一台显示器时不做移动。

## 安装

1. 安装 Hammerspoon，并按其提示授予辅助功能权限。
2. 将仓库克隆到本地，例如：

   ```sh
   git clone https://github.com/RealmX1/macos-window-tiling-and-maximization-shortcuts.git
   ```

3. 把 `window_tiling_and_maximization_shortcuts.lua` 复制到 `~/.hammerspoon/`。
4. 在 `~/.hammerspoon/init.lua` 中加入：

   ```lua
   require("window_tiling_and_maximization_shortcuts")
   ```

5. 在 Hammerspoon 菜单中选择 **Reload Config**。

如果原有配置也绑定了同一组快捷键，请用上面的加载语句替换重复绑定。若系统的自定义窗口快捷键或其他窗口管理工具占用了这组组合，也需要先移除相应占用。

移除加载语句并重新加载 Hammerspoon 配置，即可停用本模块。

## 行为边界

- 仅处理当前聚焦的普通窗口；没有聚焦窗口、对话框以及 macOS 全屏窗口会被跳过。
- `Control + Option + 方向键` 在当前显示器内贴靠；`Command + Option + Shift + 左／右箭头` 跨显示器移动，并将窗口限制在目标显示器的可用区域内。
- 应用自身的最小／最大窗口尺寸可能限制最终区域。
- 状态判断允许两点的坐标误差，以容纳显示缩放和像素取整。
- `Control + Option` 也用于 VoiceOver。使用 VoiceOver 时，应在模块的绑定处换用适合自己的组合。

## 验证

使用 Lua 5.2 或更高版本运行：

```sh
lua tests/verify_window_tiling_and_maximization_shortcuts.lua
```

检查直接加载实际模块，在隔离环境中验证四个方向的目标区域、上半屏到最大化的状态切换、最大化后的重复按键、多显示器坐标、跨显示器移动和跳过条件。测试无需 macOS，也不会操作真实窗口。GitHub Actions 会运行相同检查。

本项目提取自实际使用的窗口快捷键配置。独立模块将四个方向统一交给 Hammerspoon；不需要 Karabiner-Elements。

## 许可证

[MIT](LICENSE)
