---
--- DateTime: 10/3/22 7:51 PM
---

-- Setup logger
log = hs.logger.new("elido-hotkeys", "debug")

-- Include external libs
posix = require("posix")
require("popen3")

-- Include local libs
require("utils")
require("yabai")

-- Restart Yabai
hs.hotkey.bind("alt-shift-ctrl", "y", function()
    execTaskInShellAsync("brew services restart yabai")
end)

-- Shutdown Yabai
hs.hotkey.bind("alt-shift-ctrl", "s", function()
    execTaskInShellAsync("brew services stop yabai")
end)

-- Restart Hammerspoon
hs.hotkey.bind("alt-shift-ctrl", "h", hs.reload)

-- Focus window in direction of focused window (options: north, east, south, west)
hs.hotkey.bind("alt", "j", function()
    execTaskInShellAsync("yabai -m window --focus south")
end)
hs.hotkey.bind("alt", "k", function()
    execTaskInShellAsync("yabai -m window --focus north")
end)
hs.hotkey.bind("alt", "l", function()
    execTaskInShellAsync("yabai -m window --focus east")
end)
hs.hotkey.bind("alt", "h", function()
    execTaskInShellAsync("yabai -m window --focus west")
end)

-- Minimize window
hs.hotkey.bind("alt", "m", function()
    execTaskInShellAsync([[yabai -m window --minimize]])
    focusOnAnyVisibleWindow()
end)

-- Toggle whether to split vertically or horizontally
hs.hotkey.bind("alt", "s", function()
    execTaskInShellAsync("yabai -m window --toggle split")
end)

-- Toggle zoom to fullscreen windowed
hs.hotkey.bind("alt", "f", function()
    execTaskInShellAsync("yabai -m window --toggle zoom-fullscreen")
end)

--Toggle zoom to full panel
hs.hotkey.bind("alt-shift", "f", function()
    execTaskInShellAsync("yabai -m window --toggle zoom-parent")
end)

--Balances the windows evenly on the screen
hs.hotkey.bind("alt", "b", function()
    execTaskInShellAsync("yabai -m space --balance")
end)

-- Warp at window in direction of warped window (options: north, east, south, west)
hs.hotkey.bind("alt-shift", "j", function()
    execTaskInShellAsync("yabai -m window --warp south")
end)
hs.hotkey.bind("alt-shift", "k", function()
    execTaskInShellAsync("yabai -m window --warp north")
end)
hs.hotkey.bind("alt-shift", "l", function()
    execTaskInShellAsync("yabai -m window --warp east")
end)
hs.hotkey.bind("alt-shift", "h", function()
    execTaskInShellAsync("yabai -m window --warp west")
end)

-- Send Window to next display
hs.hotkey.bind("alt-shift", ".", function()
    coroutine.wrap(function()
        log.i("Attempting to move to next display")
        moveWindowToDisplayLTR("next")
    end)()
end)

-- Send Window to next display
hs.hotkey.bind("alt-shift", ",", function()
    coroutine.wrap(function()
        log.i("Attempting to move to prev display")
        moveWindowToDisplayLTR("prev")
    end)()
end)

-- Send window to the next space
hs.hotkey.bind("alt", ".", function()
    moveWindowToSpace("next")
end)

hs.hotkey.bind("alt", ",", function()
    moveWindowToSpace("prev")
end)

-- Switch Displays
hs.hotkey.bind("alt", "[", function()
    execTaskInShellAsync("yabai -m display --focus prev")
end)
hs.hotkey.bind("alt", "]", function()
    execTaskInShellAsync("yabai -m display --focus next")
end)

-- Create Space
hs.hotkey.bind("alt", "=", function()
    execTaskInShellAsync("yabai -m space --create")
end)
hs.hotkey.bind("alt", "-", function()
    execTaskInShellAsync("yabai -m space --destroy")
end)

-- Switch Space
hs.hotkey.bind("alt", ";", function()
    execTaskInShellAsync("yabai -m space --focus prev")
end)
hs.hotkey.bind("alt", "'", function()
    execTaskInShellAsync("yabai -m space --focus next")
end)

-- Toggle float setting of window
hs.hotkey.bind("alt", "d", function()
    execTaskInShellAsync("yabai -m window --toggle float")
end)


-- Debugging hotkeys

-- Get the current windows in focus
hs.hotkey.bind("alt-shift", "d", function()
    coroutine.wrap(function()
        -- Log the window details to the hammerspoon console
        log.i(getAllFocusedWindows())
    end)()
end)

-- Get the current windows for the focused app
hs.hotkey.bind("alt-shift", "c", function()
    coroutine.wrap(function()
        -- Log the window details to the hammerspoon console
        log.i(getAllWindowsForFocusedApp())
    end)()
end)

