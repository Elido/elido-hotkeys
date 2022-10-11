# Elido-Hotkeys

This project contains my yabai configuration as well as hotkey setup using hammerspoon. This project is for Mac only

- `src/*.lua` is symlinked to `~/.hammerspoon/*.lua`
- `yabairc` is symlinked to `~/.config/yabai/yabairc`

## Prerequisites

- [Make GNU](https://formulae.brew.sh/formula/make)
- [Yabai](https://github.com/koekeishiya/yabai)
- [Hammerspoon](https://github.com/Hammerspoon/hammerspoon)
- [jq](https://formulae.brew.sh/formula/jq)
- [LuaRocks](https://github.com/luarocks/luarocks/wiki/Installation-instructions-for-macOS)
    - [luaposix](https://github.com/luaposix/luaposix/)

## Setup

`make setup` - creates symlinks of hammerspoon lua files and yabai config in the appropriate place

## Supported Hotkeys

### Config
- ⌥ + ⇧ + ⌃ + `h`: Reload Hammerspoon config
- ⌥ + ⇧ + ⌃ + `y`: Restart Yabai
- ⌥ + ⇧ + ⌃ + `s`: Shutdown Yabai

### Window
- ⌥ + ⇧ + `j`: move window south
- ⌥ + ⇧ + `k`: move indow north
- ⌥ + ⇧ + `l`: move window east
- ⌥ + ⇧ + `h`: move window west
- ⌥ + `f`: toggle window zoom-fullscreen
- ⌥ + ⇧ + `f`: toggle window zoom-parent
- ⌥ + `.`: move window to the next space and focus it
- ⌥ + `,`: move window to the prev space and focus it
- ⌥ + `m`: minimize current window and focus one in the current space
- ⌥ + `d`: toggle whether the currently focused window floats or not

### Space
- ⌥ + `b`: toggle space balance (equalize the space windows use on the screen)
- ⌥ + `-`: create a new space on the current display
- ⌥ + `=`: delete the current space
- ⌥ + `s`: toggle window in space split

### Focus
- ⌥ + `j`: focus window south
- ⌥ + `k`: focus window north
- ⌥ + `l`: focus window east
- ⌥ + `h`: focus window west
- ⌥ + `[`: move focus to the next display
- ⌥ + `]`: move focus to the prev display
- ⌥ + `;`: move focus to prev space
- ⌥ + `'`: move focus to next space

### Debug
- ⌥ + ⇧ + `d`: Print all focused windows to hammerspoon console
- ⌥ + ⇧ + `c`: Print all windows of the focused app to hammerspoon console

## FAQ

### [Yabai performance issues](https://github.com/koekeishiya/yabai/issues/502#issuecomment-633353477)

Some long-running calls to yabai will hang hammerspoon. The simple solution is to use `hs.task.new` which runs the task on another thread. [Coroutines can be used to wait for the output](https://github.com/koekeishiya/yabai/issues/502#issuecomment-633378939), and we make use of them in [yabai.lua](src/yabai.lua)