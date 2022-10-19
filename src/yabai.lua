---
--- DateTime: 10/5/22 7:18 PM
---

local json = require('cjson')

function focusOnAnyVisibleWindow()
    -- Focus any window that is current visible
    execTaskInShellAsync([[yabai -m window --focus $(yabai -m query --windows | jq -rj '. | map(select(.["is-visible"] == true)) | .[0].id')]])
end

function getFocusedWindowId()
    return execTaskInShellSync("yabai -m query --windows | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .[0].id'")
end

function getAllFocusedWindows()
    return execTaskInShellSync("yabai -m query --windows | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .'")
end

function getFocusedSpace()
    return json.decode(execTaskInShellSync("yabai -m query --spaces | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .[0]'"))
end

function getSortedDisplays()
    local displaysStr = execTaskInShellSync("yabai -m query --displays")
    local tab = json.decode(displaysStr)

    local displays = {}
    local order = {}
    local sorted = {}

    for k, v in pairs(tab) do
        local xpos = v["frame"]["x"]
        displays[xpos] = v

        table.insert(order, xpos)
    end

    table.sort(order)

    for i,n in ipairs(order) do
        table.insert(sorted, displays[n])
    end

    return sorted
end

function moveWindowToDisplayLTR(display_sel)
    local displays = getSortedDisplays()
    local space = getFocusedSpace()
    local focusedIndex = 0
    local targetIndex = 1
    local length = 0

    for k, v in ipairs(displays) do
        length = length + 1
        if v["index"] == space["display"] then
            focusedIndex = k
        end
    end

    if display_sel == "next" then
       targetIndex = (focusedIndex % length) + 1
    elseif display_sel == "prev" then
       targetIndex = ((focusedIndex - 2) % length) + 1
    end

    log.i("focused index:", focusedIndex)
    log.i("targeted index:", targetIndex)
    log.i("space index: ", math.floor(displays[targetIndex]["spaces"][1]))

    moveWindowToSpace(math.floor(displays[targetIndex]["spaces"][1]))
end

function getAllWindowsForFocusedApp()
    return execTaskInShellSync([=[
    QUERY=$(yabai -m query --windows);
    APP=$(echo "$QUERY" | jq -rj '. | map(select(.["has-focus"] == true)) | .[0]["app"]');
    echo "$QUERY" | jq -rj ". | map(select(.[\"app\"] == \"$APP\"))"
    ]=])
end

function moveWindowToSpace(space_sel)
    -- This call will hang hammerspoon if done on the main thread (https://github.com/koekeishiya/yabai/issues/502#issuecomment-633353477)
    -- so we need to call it using hs.task and we throw it in a coroutines so we can wait for the command to complete
    coroutine.wrap(function()
        local winId = getFocusedWindowId()
        local spacesLen = tonumber(execTaskInShellSync("yabai -m query --spaces | jq -rj '. | length'"))

        if spacesLen > 1 then
            execTaskInShellAsync("yabai -m window --space " .. space_sel):waitUntilExit()
            execTaskInShellAsync("yabai -m window --focus " .. winId)
        end
    end)()
end

function moveWindowToDisplay(space_sel)
    -- This call will hang hammerspoon if done on the main thread (https://github.com/koekeishiya/yabai/issues/502#issuecomment-633353477)
    -- so we need to call it using hs.task and we throw it in a coroutines so we can wait for the command to complete
    coroutine.wrap(function()
        local winId = getFocusedWindowId()
        local spacesLen = tonumber(execTaskInShellSync("yabai -m query --spaces | jq -rj '. | length'"))

        if spacesLen > 1 then
            execTaskInShellAsync("yabai -m window --space " .. space_sel):waitUntilExit()
            execTaskInShellAsync("yabai -m window --focus " .. winId)
        end
    end)()
end
