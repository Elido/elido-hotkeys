---
--- DateTime: 10/5/22 7:18 PM
---

function focusOnAnyVisibleWindow()
    -- Focus any window that is current visible
    execTaskInShell([[yabai -m window --focus $(yabai -m query --windows | jq -rj '. | map(select(.["is-visible"] == true)) | .[0].id')]])
end

function getCurrentWindowId()
    return execTaskInShellSync("yabai -m query --windows | jq -rj '. | map(select(.[\"has-focus\"] == true)) | .[0].id'")
end

function moveWindowToSpace(space_sel)
    -- This call will hang hammerspoon if done on the main thread (https://github.com/koekeishiya/yabai/issues/502#issuecomment-633353477)
    -- so we need to call it using hs.task and we throw it in a coroutines so we can wait for the command to complete
    coroutine.wrap(function()
        local winId = getCurrentWindowId()
        local spacesLen = tonumber(execTaskInShellSync("yabai -m query --spaces | jq -rj '. | length'"))

        if spacesLen > 1 then
            execTaskInShell("yabai -m window --space " .. space_sel):waitUntilExit()
            execTaskInShell("yabai -m window --focus " .. winId)
        end
    end)()
end
