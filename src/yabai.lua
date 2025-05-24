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

function getFocusedSpace()
    -- always try to derive focus from a window if possible
    local win = getFocusedWindow()
    local spaceIndex

    if win ~= nil then
        spaceIndex = toint(win["space"])
        return json.decode(execTaskInShellSync("yabai -m query --spaces --space " .. spaceIndex))
    else
        -- if there's no window just get the space that says it's in focus
        return json.decode(execTaskInShellSync("yabai -m query --spaces | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .[0]'"))
    end
end

function getFocusedSpaceIndexFromWindow()
    local win = getFocusedWindow()

    -- if there's no window then return nil
    if win == nil then
        return nil
    end

    return toint(win["space"])
end

function getFocusedWindow()
    local winStr = execTaskInShellSync("yabai -m query --windows | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .[0]'")

    -- if no winow has focus, return nil
    if winStr == "null" then
        return nil
    end

    return json.decode(winStr)
end

function getWindow(index)
    local winStr = execTaskInShellSync("yabai -m query --windows --window " .. index)

    -- no display found with that index
    if winStr == "" then
        return nil
    end

    return json.decode(winStr)
end

function getDisplay(index)
    local disStr = execTaskInShellSync("yabai -m query --displays --display " .. index)

    -- no display found with that index
    if disStr == "" then
        return nil
    end

    return json.decode(disStr)
end

function getFocusedDisplay()
    -- always try to derive focus from a window if possible
    local win = getFocusedWindow()
    local displayIndex

    if win ~= nil then
        displayIndex = toint(win["display"])
    else
        -- if there's no focused window, get it from the space
        local space = getFocusedSpace()
        displayIndex = toint(space["display"])
    end

    return getDisplay(displayIndex)
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

    for i, n in ipairs(order) do
        table.insert(sorted, displays[n])
    end

    return sorted
end

function getAllWindowsForFocusedApp()
    return execTaskInShellSync([=[
    QUERY=$(yabai -m query --windows);
    APP=$(echo "$QUERY" | jq -rj '. | map(select(.["has-focus"] == true)) | .[0]["app"]');
    echo "$QUERY" | jq -rj ". | map(select(.[\"app\"] == \"$APP\"))"
    ]=])
end

function getFocusedDisplayIndexFromWindow(displays, win)
    local focusedIndex = 1

    for k, v in ipairs(displays) do
        if v["index"] == win["display"] then
            focusedIndex = k
        end
    end

    return focusedIndex
end

function getFocusedDisplayIndexFromSpace(displays, space)
    local focusedIndex = 1

    for k, v in ipairs(displays) do
        if v["index"] == space["display"] then
            focusedIndex = k
        end
    end

    return focusedIndex
end

-- Move window to selected space. If a window id is not provided, the currently focused window id is used
-- This call will hang hammerspoon if done on the main thread (https://github.com/koekeishiya/yabai/issues/502#issuecomment-633353477)
-- under the hood execTaskInShellSync expects to  be called within a coroutine to solve that issue
function moveWindowToSpace(space_sel, winId)
    local win

    if winId == nil then
        win = getFocusedWindow()
    else
        win = getWindow(toint(winId))
    end

    local spacesLen = toint(execTaskInShellSync("yabai -m query --spaces | jq -rj '. | length'"))

    if spacesLen > 1 then
        -- adding the window selector to move command solves some buggy behavior by yabai when dealing with windows without menubars
        execTaskInShellSync("yabai -m window " .. toint(win["id"]) .. " --space " .. space_sel)
        execTaskInShellSync("yabai -m window --focus " .. toint(win["id"]))
    end
end

-- Move the window to another space within the current display
-- If no other space exists, create one
function moveWindowToSpaceWithinDisplay(space_sel)
    local win = getFocusedWindow()
    -- There is no window focused so we do nothing
    if win == nil then
        return
    end

    local currentDisplayIndex = toint(win["display"])
    local currentSpaceIndex = toint(win["space"])
    local display = json.decode(execTaskInShellSync([[yabai -m query --displays | jq -rj ". | map(select(.[\"index\"] == ]] .. currentDisplayIndex .. [[)) | .[0]"]]))
    local spaces = display["spaces"]

    -- create a new space when only one exists on this display
    if #spaces <= 1 then
        execTaskInShellSync("yabai -m display --focus " .. currentDisplayIndex .. "; yabai -m space --create")
        display = json.decode(execTaskInShellSync([[yabai -m query --displays | jq -rj ". | map(select(.[\"index\"] == ]] .. currentDisplayIndex .. [[)) | .[0]"]]))
        spaces = display["spaces"]
    end

    local spacePos = 1
    for k, v in pairs(spaces) do
        if toint(v) == currentSpaceIndex then
            spacePos = k
        end
    end

    local targetSpace = cycleTableIndex(spaces, spacePos, space_sel)

    -- if the target is different from the spacePos then move the window!
    if targetSpace ~= spacePos then
        moveWindowToSpace(toint(spaces[targetSpace]), toint(win["id"]))
    end
end

function moveWindowToDisplayLTR(display_sel)
    local displays = getSortedDisplays()
    local win = getFocusedWindow()
    -- There is no window focused so we do nothing
    if win == nil then
        return
    end

    local focusedIndex = getFocusedDisplayIndexFromWindow(displays, win)
    local targetIndex = cycleTableIndex(displays, focusedIndex, display_sel)

    -- If there is only one display, behave like you just want to move the space
    if targetIndex == focusedIndex then
        moveWindowToSpaceWithinDisplay(display_sel)
        return
    end

    moveWindowToSpace(math.floor(displays[targetIndex]["spaces"][1]), math.floor(win["id"]))
end

function gotoDisplay(display_sel)
    local win = getFocusedWindow()
    local supportedSel = display_sel == "next" or display_sel == "prev" or display_sel == "east" or display_sel == "west"

    -- There is no window focused or the selection is not supported so use yabai builtin
    if supportedSel == false then
        execTaskInShellSync("yabai -m display --focus " .. display_sel)
        return
    end

    local displays = getSortedDisplays()
    local focusedIndex

    if win == nil then
        focusedIndex = getFocusedDisplayIndexFromSpace(displays, getFocusedSpace())
    else
        focusedIndex = getFocusedDisplayIndexFromWindow(displays, win)
    end

    local targetIndex = cycleTableIndex(displays, focusedIndex, display_sel)

    -- If there is only one display, behave like you just want to goto a space
    if targetIndex == focusedIndex then
        gotoSpace(display_sel)
        return
    end

    execTaskInShellSync("yabai -m display --focus " .. toint(displays[targetIndex]["index"]))
end

function gotoSpace(space_sel, withinDisplay)
    if space_sel == "next" or space_sel == "prev" or space_sel == "east" or space_sel == "west" then
        local focusedSpace = getFocusedSpace()
        local spaces

        if withinDisplay == true then
            local focusedDisplay = getFocusedDisplay()
            spaces = focusedDisplay["spaces"]
        else
            spaces = json.decode(execTaskInShellSync("yabai -m query --spaces"))
        end

        local spacePos = 0
        for k, v in ipairs(spaces) do
            local i

            -- spaces can be a table of space indexes or a table of tables (space objects)
            if type(v) == "number" then
                i = toint(v)
            elseif type(v) == "table" then
                i = toint(v["index"])
            end

            if i == toint(focusedSpace["index"]) then
                spacePos = k
            end
        end

        targetIndex = cycleTableIndex(spaces, spacePos, space_sel)
        execTaskInShellSync("yabai -m space --focus " .. targetIndex)
    else
        execTaskInShellSync("yabai -m space --focus " .. space_sel)
    end
end
