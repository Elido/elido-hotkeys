---
--- DateTime: 10/4/22 12:41 AM
---

px = require("posix.unistd")

function cwrap(func)
    return function()
        coroutine.wrap(func)()
    end
end


function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

function read_all(reader)
    local bufsize = 4096
    local out = {}
    local i = 1
    while true do
        local buf = px.read(reader, bufsize)
        if buf == nil or #buf == 0 then break end
        out[i] = buf
        i = i + 1
    end
    return out
end

function baseCmdWithEnv(cmd)
    local cmdt = { os.getenv("SHELL"), "-l", "-i", "-c"}
    table.insert(cmdt, cmd)
    return cmdt
end

function execTaskInShellAsync(cmdWithArgs, callback)
    coroutine.wrap(function()
        execTaskInShellSync(cmdWithArgs, callback)
    end)()
end

function execTaskInShellSync(cmdWithArgs, callback)
    if not coroutine.isyieldable() then
        log.i("this function cannot be invoked on the main Lua thread")
    end

    if callback == nil then
        callback = function(exitCode, stdOut, stdErr)  end
    end

    local done = false
    local out = nil

    local t = hs.task.new(os.getenv("SHELL"),function(exitCode, stdOut, stdErr)
        callback(exitCode, stdOut, stdErr)
        out = stdOut
        done = true
    end, {"-l", "-i", "-c", cmdWithArgs})

    t:start()

    while done == false do
        coroutine.applicationYield()
    end

    return out
end

function getenv(name)
    local val = os.getenv(name)
    if val == nil then
        val = execTaskInShellSync("echo -n $"..name)
    end
    if val == nil then
        val = ""
    end
    return val
end