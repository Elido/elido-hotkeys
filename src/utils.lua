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

function execTaskInShellAsync(cmdWithArgs, callback, withEnv)
    coroutine.wrap(function()
        execTaskInShellSync(cmdWithArgs, callback, withEnv)
    end)()
end

function append(source, ...)
	for k, v in ipairs({...}) do
		table.insert(source, v)
	end
	return source
end

-- execTaskInShellSync runs a command and waits for the output. All commands executed with a path environment variable that mirrors a logged in shell
-- @param cmdWithArgs - a string with the bash commands to runs
-- @param callback - a callback function to trigger once the command completes. Parrams for the callback fn should be exitCode, stdOut, and stdErr
-- @param withLogin - whether to run the command in a shell that has logged in resulting in common profile and env variable settings getting applied
execTaskInShellSync = (function()
	local pathEnv = ""
	local fn = function (cmdWithArgs, callback, withLogin)
		if not coroutine.isyieldable() then
			log.i("this function cannot be invoked on the main Lua thread")
		end

		if callback == nil then
			callback = function(exitCode, stdOut, stdErr)  end
		end

		local done = false
		local out = nil

		local cmd = {}
		if withLogin == true then
			append(cmd, "-l", "-i", "-c")
		else
			append(cmd,"-c")
		end

		if pathEnv ~= "" then
			table.insert(cmd, "export PATH=\""..pathEnv.."\";"..cmdWithArgs)
		else
			table.insert(cmd, cmdWithArgs)
		end

		local t = hs.task.new(os.getenv("SHELL"),function(exitCode, stdOut, stdErr)
			callback(exitCode, stdOut, stdErr)
			out = stdOut
			done = true
		end, cmd)

		t:start()

		while done == false do
			coroutine.applicationYield()
		end

		return out
	end

	return function (cmdWithArgs, callback, withEnv)
		if pathEnv == "" then
			-- we are safe to call fn here because it should already be in a coroutine
			pathEnv = fn("echo -n $PATH", nil, true)
		end
		return fn(cmdWithArgs, callback, withEnv)
	end
end)()

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