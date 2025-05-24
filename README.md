# Elido-Hotkeys

This project contains my yabai configuration as well as hotkey setup using hammerspoon. It's multi-display friendly and supports cycling through spaces and displays. This project is for Mac only

## Prerequisites

- [Make GNU](https://formulae.brew.sh/formula/make)
- [Yabai](https://github.com/koekeishiya/yabai)
- [Hammerspoon](https://github.com/Hammerspoon/hammerspoon)
- [jq](https://formulae.brew.sh/formula/jq)
- [LuaRocks](https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-macOS)
    - [lua-cjson](https://luarocks.org/modules/openresty/lua-cjson)([docs](https://kyne.com.au/~mark/software/lua-cjson-manual.html))

## Setup

`make setup` - creates symlinks of hammerspoon lua files and yabai config in the appropriate place
- `src/*.lua` is symlinked to `~/.hammerspoon/*.lua`
- `yabairc` is symlinked to `~/.config/yabai/yabairc`


## Supported Hotkeys

### Config
| hotkey          | description               |
|-----------------|---------------------------|
| ⌥ + ⇧ + ⌃ + `h` | Reload Hammerspoon config |
| ⌥ + ⇧ + ⌃ + `y` | Restart Yabai             |
| ⌥ + ⇧ + ⌃ + `s` | Shutdown Yabai            |

### Window
| hotkey      | description                                                               |
|-------------|---------------------------------------------------------------------------|
| ⌥ + ⇧ + `j` | move window south                                                         |
| ⌥ + ⇧ + `k` | move window north                                                         |
| ⌥ + ⇧ + `l` | move window east                                                          |
| ⌥ + ⇧ + `h` | move window west                                                          |
| ⌥ + `f`     | toggle window zoom - fullscreen                                           |
| ⌥ + ⇧ + `f` | toggle window zoom - parent                                               |
| ⌥ + `.`     | move window to the next space **within the current display** and focus it |
| ⌥ + `,`     | move window to the prev space **within the current display** and focus it |
| ⌥ + ⇧ + `.` | move window to the east display and focus it                              |
| ⌥ + ⇧ + `,` | move window to the west display and focus it                              |
| ⌥ + `m`     | minimize current window and focus one in the current space                |
| ⌥ + `d`     | toggle whether the currently focused window floats or not                 |

### Space
| hotkey          | description                                                         |
|-----------------|---------------------------------------------------------------------|
| ⌥ + `b`         | toggle space balance (equalize the space windows use on the screen) |
| ⌥ + `-`         | create a new space on the current display                           |
| ⌥ + `=`         | delete the current space                                            |
| ⌥ + `s`         | toggle window in space split                                        |

### Focus

| hotkey          | description                                                     |
|-----------------|-----------------------------------------------------------------|
| ⌥ + `j`         | focus window south                                              |
| ⌥ + `k`         | focus window north                                              |
| ⌥ + `l`         | focus window east                                               |
| ⌥ + `h`         | focus window west                                               |
| ⌥ + `[`         | move focus to the west display (cycle)                          |
| ⌥ + `]`         | move focus to the east display (cycle)                          |
| ⌥ + `;`         | move focus to prev space **within the current display** (cycle) |
| ⌥ + `'`         | move focus to next space **within the current display** (cycle) |

## FAQ

### [Yabai performance issues](https://github.com/koekeishiya/yabai/issues/502#issuecomment-633353477)

Some long-running calls to yabai will hang hammerspoon. The simple solution is to use `hs.task.new` which runs the task on another thread. [Coroutines can be used to wait for the output](https://github.com/koekeishiya/yabai/issues/502#issuecomment-633378939), and we make use of them in [yabai.lua](src/yabai.lua)

### Slow hammerspoon config initial and reload time

We use a `SHELL` with the login flag to pull the `PATH` env and as well as our debug flag `ELIDO_HOTKEYS_DEBUG`. The speed is dependant on the time it takes for your shell prompt to load
