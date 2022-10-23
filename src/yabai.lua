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

function getFocusedSpaceIndexFromWindow()
    local win = getFocusedWindow()

    -- if there's no window then return nil
    if win == nil then return nil end

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


function getAllWindowsForFocusedApp()
    return execTaskInShellSync([=[
    QUERY=$(yabai -m query --windows);
    APP=$(echo "$QUERY" | jq -rj '. | map(select(.["has-focus"] == true)) | .[0]["app"]');
    echo "$QUERY" | jq -rj ". | map(select(.[\"app\"] == \"$APP\"))"
    ]=])
end

-- Move window to selected space. If a window id is not provided, the currently focused window id is used
-- This call will hang hammerspoon if done on the main thread (https://github.com/koekeishiya/yabai/issues/502#issuecomment-633353477)
-- under the hood execTaskInShellSync expects to  be called within a coroutine to solve that issue
function moveWindowToSpace(space_sel, winId)
	if winId == nil then
		winId = getFocusedWindowId()
	end

	local spacesLen = toint(execTaskInShellSync("yabai -m query --spaces | jq -rj '. | length'"))

	if spacesLen > 1 then
		execTaskInShellSync("yabai -m window --space " .. space_sel)
		execTaskInShellSync("yabai -m window --focus " .. winId)
	end
end

-- Move the window to another space within the current display
-- If no other space exist, create one
function moveWindowToSpaceWithinDisplay(space_sel)
    local win = getFocusedWindow()
    -- There is no window focused so we do nothing
    if win == nil then return end

    local currentDisplayIndex = toint(win["display"])
    local currentSpaceIndex = toint(win["space"])
	local display = json.decode(execTaskInShellSync([[yabai -m query --displays | jq -rj ". | map(select(.[\"index\"] == ]]..currentDisplayIndex..[[)) | .[0]"]]))
	local spaces = display["spaces"]

	local spacePos = 1
	for k, v in pairs(spaces) do
		if toint(v) == currentSpaceIndex then
			spacePos = k
		end
	end

	local targetSpace = cycleTableIndex(spaces, spacePos, space_sel)
	if targetSpace ~= spacePos then
		moveWindowToSpace(toint(spaces[targetSpace]), toint(win["id"]))
	end
end

function moveWindowToDisplayLTR(display_sel)
    local displays = getSortedDisplays()
    local win = getFocusedWindow()
    -- There is no window focused so we do nothing
    if win == nil then return end

    local focusedIndex = 1
    local targetIndex = 1

    for k, v in ipairs(displays) do
        if v["index"] == win["display"] then
            focusedIndex = k
        end
    end

	targetIndex = cycleTableIndex(displays, focusedIndex, display_sel)

	-- If there is only one display, behave like you just want to move the space
	if targetIndex == focusedIndex then
		moveWindowToSpaceWithinDisplay(display_sel)
		return
	end

    moveWindowToSpace(math.floor(displays[targetIndex]["spaces"][1]), math.floor(win["id"]))
end

function gotoSpace(space_sel)
    if space_sel == "next" or space_sel == "prev" then
        local focusedSpaceIndex = getFocusedSpaceIndexFromWindow()
        local spaces = json.decode(execTaskInShellSync("yabai -m query --spaces"))
        local spacePos = 0

        for k,v in ipairs(spaces) do
            -- focusedSpaceIndex might be nil if no window was focused, so we fallback to yabai's space focus
            if focusedSpaceIndex == nil then
                if v["has-focus"] == true then
                    spacePos = k
                end
            else
                if toint(v["index"]) == focusedSpaceIndex then
                    spacePos = k
                end
            end
        end

        targetIndex = cycleTableIndex(spaces, spacePos, space_sel)
        execTaskInShellSync("yabai -m space --focus "..targetIndex)
    else
       execTaskInShellSync("yabai -m space --focus "..space_sel)
    end



end