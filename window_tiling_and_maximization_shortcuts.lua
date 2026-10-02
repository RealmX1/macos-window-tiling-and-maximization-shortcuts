-- 窗口贴靠、最大化与跨显示器移动快捷键，依赖 Hammerspoon。
local windowTilingUnitRectanglesByArrowKey = {
  left = { x = 0, y = 0, w = 0.5, h = 1 },
  right = { x = 0.5, y = 0, w = 0.5, h = 1 },
  up = { x = 0, y = 0, w = 1, h = 0.5 },
  down = { x = 0, y = 0.5, w = 1, h = 0.5 },
}

local function tileOrMaximizeFocusedStandardWindowForArrowShortcut(shortcutArrowKey)
  local focusedStandardWindowForTiling = hs.window.focusedWindow()
  if not focusedStandardWindowForTiling or not focusedStandardWindowForTiling:isStandard()
      or focusedStandardWindowForTiling:isFullScreen() then
    return
  end

  if shortcutArrowKey == "up" then
    local focusedWindowFrame = focusedStandardWindowForTiling:frame()
    local availableScreenFrame = focusedStandardWindowForTiling:screen():frame()
    -- 容许两点的像素取整误差，以实际窗口区域判断上半屏／最大化状态。
    local windowFrameComparisonTolerancePoints = 2
    local focusedWindowMatchesTopHalfOrMaximizedFrame =
        math.abs(focusedWindowFrame.x - availableScreenFrame.x) <= windowFrameComparisonTolerancePoints
        and math.abs(focusedWindowFrame.y - availableScreenFrame.y) <= windowFrameComparisonTolerancePoints
        and math.abs(focusedWindowFrame.w - availableScreenFrame.w) <= windowFrameComparisonTolerancePoints
        and (math.abs(focusedWindowFrame.h - availableScreenFrame.h / 2) <= windowFrameComparisonTolerancePoints
          or math.abs(focusedWindowFrame.h - availableScreenFrame.h) <= windowFrameComparisonTolerancePoints)
    if focusedWindowMatchesTopHalfOrMaximizedFrame then
      focusedStandardWindowForTiling:maximize(0)
      return
    end
  end

  focusedStandardWindowForTiling:moveToUnit(windowTilingUnitRectanglesByArrowKey[shortcutArrowKey], 0)
end

local windowTilingMaximizationAndDisplayMovementHotkeyBindingsByAction = {}
for shortcutArrowKey in pairs(windowTilingUnitRectanglesByArrowKey) do
  windowTilingMaximizationAndDisplayMovementHotkeyBindingsByAction[shortcutArrowKey] = assert(
    hs.hotkey.bind({ "ctrl", "alt" }, shortcutArrowKey, function()
      tileOrMaximizeFocusedStandardWindowForArrowShortcut(shortcutArrowKey)
    end),
    "无法绑定 Control + Option + " .. shortcutArrowKey .. "，请检查已有快捷键占用"
  )
end

local function moveFocusedStandardWindowToRelativeDisplay(relativeDisplayTraversalDirection)
  local focusedWindowForDisplayMovement = hs.window.focusedWindow()
  if not focusedWindowForDisplayMovement or not focusedWindowForDisplayMovement:isStandard()
      or focusedWindowForDisplayMovement:isFullScreen() then
    return
  end
  local currentScreenForDisplayMovement = focusedWindowForDisplayMovement:screen()
  local destinationScreenForDisplayMovement
  if relativeDisplayTraversalDirection == "previous" then
    destinationScreenForDisplayMovement = currentScreenForDisplayMovement:previous()
  else
    destinationScreenForDisplayMovement = currentScreenForDisplayMovement:next()
  end
  if destinationScreenForDisplayMovement and destinationScreenForDisplayMovement ~= currentScreenForDisplayMovement then
    -- 按目标显示器的可用区域缩放，保留窗口的相对位置和尺寸比例。
    focusedWindowForDisplayMovement:moveToScreen(destinationScreenForDisplayMovement, false, true, 0)
  end
end

windowTilingMaximizationAndDisplayMovementHotkeyBindingsByAction.previousDisplay = assert(
  hs.hotkey.bind({ "cmd", "alt", "shift" }, "left", function() moveFocusedStandardWindowToRelativeDisplay("previous") end),
  "无法绑定 Command + Option + Shift + 左箭头"
)
windowTilingMaximizationAndDisplayMovementHotkeyBindingsByAction.nextDisplay = assert(
  hs.hotkey.bind({ "cmd", "alt", "shift" }, "right", function() moveFocusedStandardWindowToRelativeDisplay("next") end),
  "无法绑定 Command + Option + Shift + 右箭头"
)

return windowTilingMaximizationAndDisplayMovementHotkeyBindingsByAction
