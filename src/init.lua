-- Setup logger
log = hs.logger.new("elido-hotkeys", "debug")
debugMode = false

-- Include local libs
require("utils")
require("yabai")

-- Track the last active display and space
lastDisplayIndex = nil
lastSpaceIndex = nil
currentDisplayIndex = nil
currentSpaceIndex = nil

function updateDisplayHistory()
    local space = getFocusedSpace()
    local display = toint(space["display"])
    local spaceIdx = toint(space["index"])

    if currentDisplayIndex ~= nil and display ~= currentDisplayIndex then
        lastDisplayIndex = currentDisplayIndex
        lastSpaceIndex = currentSpaceIndex
    end

    currentDisplayIndex = display
    currentSpaceIndex = spaceIdx
end

-- Watch for space changes to keep track of display history
spaceWatcher = hs.spaces.watcher.new(function()
    updateDisplayHistory()
end)
spaceWatcher:start()

-- Watch for window focus changes as well
winWatcher = hs.window.filter.new(nil)
winWatcher:subscribe(hs.window.filter.windowFocused, function()
    updateDisplayHistory()
end)

-- Initialize history state
updateDisplayHistory()

-- Debugging hotkeys
cwrap(function()
    debugMode = getenv("ELIDO_HOTKEYS_DEBUG") == "1"

    -- Check if debug mode is enabled
    if debugMode then
        log.i("Debug enabled")

        -- Get the current windows in focus
        hs.hotkey.bind("alt-shift", "d", cwrap(function()
            -- Log the window details to the hammerspoon console
            log.i(getAllFocusedWindows())
        end))

        -- Get the current windows for the focused app
        hs.hotkey.bind("alt-shift", "c", cwrap(function()
            -- Log the window details to the hammerspoon console
            log.i(getAllWindowsForFocusedApp())
        end))

        -- Get the focused space
        hs.hotkey.bind("alt-shift", "z", cwrap(function()
            -- Log the window details to the hammerspoon console
            log.i(dump(getFocusedSpace()))
        end))
    end

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
    hs.hotkey.bind("alt", "m", cwrap(function()
        execTaskInShellSync([[yabai -m window --minimize]])
        focusOnAnyVisibleWindow()
    end))

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
    hs.hotkey.bind("alt-shift", ".", cwrap(function()
        moveWindowToDisplayLTR("east")
    end))

    -- Send Window to next display
    hs.hotkey.bind("alt-shift", ",", cwrap(function()
        moveWindowToDisplayLTR("west")
    end))

    -- Send window to the last active display/space
    hs.hotkey.bind("alt-shift", "p", cwrap(function()
        moveWindowToLastDisplaySpace()
    end))

    -- Send window to the next space
    hs.hotkey.bind("alt", ".", cwrap(function()
        moveWindowToSpaceWithinDisplay("next")
    end))

    hs.hotkey.bind("alt", ",", cwrap(function()
        moveWindowToSpaceWithinDisplay("prev")
    end))

    -- Switch Displays
    hs.hotkey.bind("alt", "[", cwrap(function()
        gotoDisplay("west")
    end))
    hs.hotkey.bind("alt", "]", cwrap(function()
        gotoDisplay("east")
    end))

    -- Create Space
    hs.hotkey.bind("alt", "=", function()
        execTaskInShellAsync("yabai -m space --create")
    end)
    hs.hotkey.bind("alt", "-", function()
        execTaskInShellAsync("yabai -m space --destroy")
    end)

    -- Switch Space
    hs.hotkey.bind("alt", ";", cwrap(function()
        gotoSpace("prev", true)
    end))
    hs.hotkey.bind("alt", "'", cwrap(function()
        gotoSpace("next", true)
    end))

    -- Toggle float setting of window
    hs.hotkey.bind("alt", "d", function()
        execTaskInShellAsync("yabai -m window --toggle float")
    end)

end)()
