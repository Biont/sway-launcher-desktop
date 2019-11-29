# sway-launcher-desktop [![Build Status](https://travis-ci.org/Biont/sway-launcher-desktop.svg?branch=master)](https://travis-ci.org/Biont/sway-launcher-desktop)

![screenshot_2019-10-25-213740](https://user-images.githubusercontent.com/4208996/67599848-3a1f3680-f771-11e9-9715-da6e943ae14e.png)

This is a TUI-based launcher menu made with bash and the amazing [fzf](https://github.com/junegunn/fzf).
Despite its name, it does not (read: no longer) depend on the Sway window manager in any way and can be used with just about any WM.

## Features
- Lists and executes available binaries
- Lists and executes .desktop files (entries as well as actions)
- Shows a preview window containing `whatis` info of binaries and the `Comment=` section of .desktop files
- History support which will highlight recently used entries. (Inspried by [this nice script which inspired me to create my own](https://gitlab.com/FlyingWombat/my-scripts/blob/master/sway-launcher))
- Colored output and glyphs for the different entry types
- Entries are lazily piped into fzf eliminating any lag during startup

## Installation

Make sure you have `fzf` installed and download this repository. 
Arch Linux used can also grab it from the AUR (thanks @turtlewit)

* [sway-launcher-desktop](https://aur.archlinux.org/packages/sway-launcher-desktop/)
* [sway-launcher-desktop-git](https://aur.archlinux.org/packages/sway-launcher-desktop-git/)

Configure it in Sway like this:
```
for_window [class="URxvt" instance="launcher"] floating enable, border pixel 10, sticky enable
set $menu exec urxvt -geometry 55x18 -name launcher -e env TERMINAL_COMMAND="urxvt -e" /path/to/repo/sway-launcher-desktop.sh
bindsym $mod+d exec $menu
```



### Setup a Terminal command
Some of your desktop entries will probably be TUI programs that expect to be launched in a new terminal window. Those entries have the `Terminal=true` flag set and you need to tell the launcher which terminal emulator to use. Pass the `TERMINAL_COMMAND` environment variable with your terminal startup command to the script to use your preferred terminal emulator. The script will default to `urxvt -e`

## Extending the launcher

In addition to desktop application entries and binaries, you can extend `sway-launcher-desktop` with custom item providers.
If will read the configuration of custom item providers from `$HOME/.config/sway-launcher-desktop/providers.conf`.
The structure looks like this:

```
[my-provider]
list_cmd=echo -e 'my-custom-entry\034my-provider\034  My custom provider'
preview_cmd=echo -e 'This is the preview of {1}'
launch_cmd=notify-send 'I am now launching {1}'
```

The `list_cmd` generated the list of entries. For each entry, it has to print the following columns, separated by the `\034` field separator character:
1. The item to launch. This will get passed to `preview_cmd` and `launch_cmd` as `{1}`
2. The name of your provider (the same as what what you put inside the brackets, so `my-provider` in this example)
3. The text that appears in the `fzf` window. You might want to prepend it with a glyph and add some color via ANSI escape codes
4. (optional) Metadata that you can pass to `preview_cmd` and `launch_cmd` as `{2}`. For example, this is used to specify a specific Desktop Action inside a .desktop file

The `preview_cmd` renders the contents of the `fzf` preview panel. You can use the template variable `{1}` in your command, which will be substituted with the value of the selected item.

The `launch_cmd` is fired when the user has selected one of the provider's entries.