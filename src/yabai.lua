local json = require('cjson')

function focusOnAnyVisibleWindow()
    -- Focus any window that is current visible
    execTaskInShellSync([[yabai -m window --focus $(yabai -m query --windows | jq -rj '. | map(select(.["is-visible"] == true)) | .[0].id')]])
end

function getFocusedWindowId()
    return execTaskInShellSync("yabai -m query --windows | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .[0].id'")
end

function getAllFocusedWindows()
    return execTaskInShellSync("yabai -m query --windows | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .'")
end

-- Gets the currently focused space. It can be a space different from the space of the currently focused window.
-- This is especially true if the window doesn't have a top menu
function getFocusedSpace()
    return json.decode(execTaskInShellSync("yabai -m query --spaces | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .[0]'"))
end

function getFocusedWindow()
    return json.decode(execTaskInShellSync("yabai -m query --windows | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .[0]'"))
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
    local win = getFocusedWindow()
    local focusedIndex = 1
    local targetIndex = 1
    local length = 0

    for k, v in ipairs(displays) do
        length = length + 1
        if v["index"] == win["display"] then
            focusedIndex = k
        end
    end

    if display_sel == "next" then
       targetIndex = (focusedIndex % length) + 1
    elseif display_sel == "prev" then
       targetIndex = ((focusedIndex - 2) % length) + 1
    end

    moveWindowToSpace(math.floor(displays[targetIndex]["spaces"][1]), math.floor(win["id"]))
end

function getAllWindowsForFocusedApp()
    return execTaskInShellSync([=[
    QUERY=$(yabai -m query --windows);
    APP=$(echo "$QUERY" | jq -rj '. | map(select(.["has-focus"] == true)) | .[0]["app"]');
    echo "$QUERY" | jq -rj ". | map(select(.[\"app\"] == \"$APP\"))"
    ]=])
end

-- Move window to selected space. If a window id is not provided, the currently focused window id is used
function moveWindowToSpace(space_sel, winId)
    -- This call will hang hammerspoon if done on the main thread (https://github.com/koekeishiya/yabai/issues/502#issuecomment-633353477)
    -- so we need to call it using hs.task and we throw it in a coroutines so we can wait for the command to complete
    coroutine.wrap(function()

        if winId == null then
            winId = getFocusedWindowId()
        end

        local spacesLen = tonumber(execTaskInShellSync("yabai -m query --spaces | jq -rj '. | length'"))

        if spacesLen > 1 then
            execTaskInShellSync("yabai -m window --space " .. space_sel)
            execTaskInShellSync("yabai -m window --focus " .. winId)
        end
    end)()
end