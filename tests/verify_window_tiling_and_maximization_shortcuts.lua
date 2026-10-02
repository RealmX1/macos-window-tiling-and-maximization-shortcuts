-- 在隔离环境中运行实际模块，不需要 macOS，也不会移动用户窗口。
local verificationScriptPath = debug.getinfo(1, "S").source:sub(2)
local verificationScriptDirectory = verificationScriptPath:match("^(.*)[/\\]") or "."
local shortcutModulePath = verificationScriptDirectory .. "/../window_tiling_and_maximization_shortcuts.lua"
local shortcutCallbacksByArrowKey = {}
local displayMovementShortcutCallbacksByArrowKey = {}
local focusedWindowForVerification
local observedWindowAction
local isolatedShortcutEnvironment = {
  math = math,
  pairs = pairs,
  assert = assert,
  hs = {
    window = { focusedWindow = function() return focusedWindowForVerification end },
    hotkey = {
      bind = function(modifiers, arrowKey, callback)
        local callbacksForModifierCombination
        if #modifiers == 2 then
          assert(modifiers[1] == "ctrl" and modifiers[2] == "alt")
          callbacksForModifierCombination = shortcutCallbacksByArrowKey
        else
          assert(#modifiers == 3 and modifiers[1] == "cmd" and modifiers[2] == "alt" and modifiers[3] == "shift")
          assert(arrowKey == "left" or arrowKey == "right")
          callbacksForModifierCombination = displayMovementShortcutCallbacksByArrowKey
        end
        assert(not callbacksForModifierCombination[arrowKey], "出现重复绑定")
        callbacksForModifierCombination[arrowKey] = callback
        return { arrowKey = arrowKey }
      end,
    },
  },
}
local shortcutHotkeyBindings = assert(loadfile(shortcutModulePath, "t", isolatedShortcutEnvironment))()
for _, arrowKey in ipairs({ "left", "right", "up", "down" }) do
  assert(shortcutHotkeyBindings[arrowKey] and shortcutCallbacksByArrowKey[arrowKey])
end
assert(shortcutHotkeyBindings.previousDisplay and displayMovementShortcutCallbacksByArrowKey.left)
assert(shortcutHotkeyBindings.nextDisplay and displayMovementShortcutCallbacksByArrowKey.right)

local availableScreenFrame = { x = -2560, y = -894, w = 2560, h = 2880 }
local previousScreenForVerification = { verificationActionName = "previousDisplay" }
local nextScreenForVerification = { verificationActionName = "nextDisplay" }
local currentScreenForVerification = {
  frame = function() return availableScreenFrame end,
  previous = function() return previousScreenForVerification end,
  next = function() return nextScreenForVerification end,
}
local function verifyShortcutDecision(windowFrame, arrowKey, expectedAction, isFullScreen, isStandard, useDisplayMovementShortcut)
  observedWindowAction = nil
  focusedWindowForVerification = windowFrame and {
    isStandard = function() return isStandard ~= false end,
    isFullScreen = function() return isFullScreen == true end,
    frame = function() return windowFrame end,
    screen = function() return currentScreenForVerification end,
    maximize = function(_, duration)
      assert(duration == 0)
      observedWindowAction = "maximize"
      windowFrame = availableScreenFrame
    end,
    moveToUnit = function(_, unitRectangle, duration)
      assert(duration == 0)
      observedWindowAction = { unitRectangle.x, unitRectangle.y, unitRectangle.w, unitRectangle.h }
      windowFrame = {
        x = availableScreenFrame.x + unitRectangle.x * availableScreenFrame.w,
        y = availableScreenFrame.y + unitRectangle.y * availableScreenFrame.h,
        w = unitRectangle.w * availableScreenFrame.w,
        h = unitRectangle.h * availableScreenFrame.h,
      }
    end,
    moveToScreen = function(_, destinationScreen, noResize, ensureInScreenBounds, duration)
      assert(noResize == false and ensureInScreenBounds == true and duration == 0)
      observedWindowAction = destinationScreen.verificationActionName
    end,
  } or nil
  if useDisplayMovementShortcut then
    displayMovementShortcutCallbacksByArrowKey[arrowKey]()
  else
    shortcutCallbacksByArrowKey[arrowKey]()
  end
  if type(expectedAction) == "table" then
    assert(type(observedWindowAction) == "table", "预期调整窗口区域")
    for index, expectedCoordinate in ipairs(expectedAction) do
      assert(observedWindowAction[index] == expectedCoordinate, "目标窗口区域不符合预期")
    end
  else
    assert(observedWindowAction == expectedAction, "窗口状态判断不符合预期")
  end
  return windowFrame
end

local ordinaryWindowFrame = { x = -2400, y = -600, w = 800, h = 600 }
local topHalfWindowFrame = { x = -2560, y = -894, w = 2560, h = 1440 }
verifyShortcutDecision(ordinaryWindowFrame, "left", { 0, 0, 0.5, 1 })
verifyShortcutDecision(ordinaryWindowFrame, "right", { 0.5, 0, 0.5, 1 })
verifyShortcutDecision(ordinaryWindowFrame, "up", { 0, 0, 1, 0.5 })
verifyShortcutDecision(ordinaryWindowFrame, "down", { 0, 0.5, 1, 0.5 })
verifyShortcutDecision(topHalfWindowFrame, "up", "maximize")
verifyShortcutDecision({ x = -2561, y = -893, w = 2561, h = 1441 }, "up", "maximize")
verifyShortcutDecision({ x = -2560, y = -894, w = 2560, h = 2880 }, "up", { 0, 0, 1, 0.5 })
verifyShortcutDecision({ x = -2561, y = -893, w = 2561, h = 2879 }, "up", { 0, 0, 1, 0.5 })
verifyShortcutDecision({ x = -2560, y = -894, w = 2560, h = 2000 }, "up", { 0, 0, 1, 0.5 })
verifyShortcutDecision({ x = -2560, y = 546, w = 2560, h = 1440 }, "up", { 0, 0, 1, 0.5 })
verifyShortcutDecision(topHalfWindowFrame, "down", { 0, 0.5, 1, 0.5 })
verifyShortcutDecision(nil, "up", nil)
verifyShortcutDecision(ordinaryWindowFrame, "up", nil, true)
verifyShortcutDecision(ordinaryWindowFrame, "up", nil, false, false)
local windowFrameAfterSequentialUpPresses = ordinaryWindowFrame
for _, expectedAction in ipairs({ { 0, 0, 1, 0.5 }, "maximize", { 0, 0, 1, 0.5 }, "maximize" }) do
  windowFrameAfterSequentialUpPresses = verifyShortcutDecision(windowFrameAfterSequentialUpPresses, "up", expectedAction)
end
availableScreenFrame = { x = 0, y = 30, w = 2560, h = 1410 }
verifyShortcutDecision({ x = 0, y = 30, w = 2560, h = 705 }, "up", "maximize")
verifyShortcutDecision(ordinaryWindowFrame, "left", "previousDisplay", false, true, true)
verifyShortcutDecision(ordinaryWindowFrame, "right", "nextDisplay", false, true, true)
verifyShortcutDecision(nil, "left", nil, false, true, true)
verifyShortcutDecision(ordinaryWindowFrame, "right", nil, true, true, true)
verifyShortcutDecision(ordinaryWindowFrame, "left", nil, false, false, true)
previousScreenForVerification = currentScreenForVerification
nextScreenForVerification = currentScreenForVerification
verifyShortcutDecision(ordinaryWindowFrame, "left", nil, false, true, true)
verifyShortcutDecision(ordinaryWindowFrame, "right", nil, false, true, true)
print("通过 26 项检查：四方向贴靠、上半屏与最大化循环、跨显示器移动、单显示器与跳过条件。")
