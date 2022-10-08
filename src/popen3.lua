---
--- DateTime: 10/4/22 11:34 PM
--- Inspired by: https://stackoverflow.com/a/16515126
---

px = require("posix.unistd")
pxw = require("posix.sys.wait")

--
-- Simple popen3() implementation
--
function popen3(path, ...)
    local r1, w1 = px.pipe()
    local r2, w2 = px.pipe()
    local r3, w3 = px.pipe()

    assert((r1 ~= nil or r2 ~= nil or r3 ~= nil), "pipe() failed")

    local pid, err = px.fork()
    assert(pid ~= nil, "fork() failed")
    if pid == 0 then
        px.close(w1)
        px.close(r2)
        px.dup2(r1, px.fileno(io.stdin))
        px.dup2(w2, px.fileno(io.stdout))
        px.dup2(w3, px.fileno(io.stderr))
        px.close(r1)
        px.close(w2)
        px.close(w3)

        local ret, err = px.execp(path, table.unpack({...}))
        assert(ret ~= nil, "execp() failed")

        px._exit(1)
        return
    end

    px.close(r1)
    px.close(w2)
    px.close(w3)

    return pid, w1, r2, r3
end

--
-- Pipe input into cmd + optional arguments and wait for completion
-- and then return status code, stdout and stderr from cmd.
--
function pipe_simple(input, cmd, ...)
    --
    -- Launch child process
    --
    local pid, w, r, e = popen3(cmd, table.unpack({...}))
    assert(pid ~= nil, "filter() unable to popen3()")

    --
    -- Write to popen3's stdin, important to close it as some (most?) proccess
    -- block until the stdin pipe is closed
    --
    px.write(w, input)
    px.close(w)

    --
    -- Read popen3's stdout via Posix file handle
    --
    local stdout = read_all(r)

    --
    -- Read popen3's stderr via Posix file handle
    --
    local stderr = read_all(e)

    --
    -- Clean-up child (no zombies) and get return status
    --
    local wait_pid, wait_cause, wait_status = pxw.wait(pid)

    log.i("wait data:",wait_pid, wait_cause, wait_status)

    return wait_status, table.concat(stdout), table.concat(stderr)
end