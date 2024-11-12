# sway-launcher-desktop ![Build Status](https://github.com/Biont/sway-launcher-desktop/workflows/CI/badge.svg)

![screenshot_2019-10-25-213740](https://user-images.githubusercontent.com/4208996/67599848-3a1f3680-f771-11e9-9715-da6e943ae14e.png)

This is a TUI-based launcher menu made with bash and the amazing [fzf](https://github.com/junegunn/fzf).
Despite its name, it does not (read: no longer) depend on the Sway window manager in any way and can be used with just about any WM.

## Features
- Lists and executes available binaries
- Lists and executes .desktop files (entries as well as actions)
- Does not depend on `xdg-utils`. Just pure bash and `awk` (specifically gawk)
- Shows a preview window containing `whatis` info of binaries and the `Comment=` section of .desktop files
- History support which will highlight recently used entries
- Colored output and glyphs for the different entry types
- Entries are lazily piped into `fzf` eliminating any lag during startup
- Optional support for the XDG Autostart specification
- Executes arbitrary custom commands (if there are no other matches)

## Installation

Make sure you have `fzf` and `awk` installed and download this repository. 
To be precise, the script specifically depends on GNU awk (`gawk`) so check what flavour your distribution provides.

Arch Linux users can also grab it from the AUR (thanks @turtlewit)

* [sway-launcher-desktop](https://aur.archlinux.org/packages/sway-launcher-desktop/)
* [sway-launcher-desktop-git](https://aur.archlinux.org/packages/sway-launcher-desktop-git/)

Configure it in Sway like this:
```
for_window [app_id="^launcher$"] floating enable, sticky enable, resize set 30 ppt 60 ppt, border pixel 10
set $menu exec $term -a launcher -e /path/to/repo/sway-launcher-desktop.sh
bindsym $mod+d exec $menu
```
(this example was made with `term=foot` in mind; it may need to be adjusted for other terminals)

You can override the default icons/glyphs by setting the appropriate GLYPH_ variable in your $menu command, e.g.:
```
set $menu exec $term -e env GLYPH_COMMAND="" GLYPH_DESKTOP="" GLYPH_PROMPT="? " sway-launcher
```

If `fzf` is not in your `$PATH` you can specify the path by supplying a value to the `FZF_COMMAND` variable.
```
set $menu exec $term -e env FZF_COMMAND="/path/to/fzf" sway-launcher
```

By default, the launcher will use a generic & WM-agnostic command to launch the selected program. 
However, it will detect if its output is being piped to another program and merely print 
the selected command in that case - instead of launching it by itself. You can use this to integrate the launcher with other tools.
For example, if you wish to launch your programs with `swaymsg exec`, you can do that like this¹:

```shell
 swaymsg exec "$(./sway-launcher-desktop.sh)"
```

### Set up a Terminal command
Some of your desktop entries will probably be TUI programs that expect to be launched in a new terminal window. Those entries have the `Terminal=true` flag set and you need to tell the launcher which terminal emulator to use. Pass the `TERMINAL_COMMAND` environment variable with your terminal startup command to the script to use your preferred terminal emulator. The script will default to `$TERMINAL -e`

### Configure application autostart
If you want to be able to autostart applications , this script provides a function to handle them for you. Simply run `sway-launcher-desktop.sh autostart` in your `.bashrc`, at the end of your i3/sway config, or wherever else you deem fit.

### Configure fzf preview window
You can configure the fzf preview window using the environment variable `PREVIEW_WINDOW` (default: `up:2:noborder`). For example, if you prefer a taller window, you could use `PREVIEW_WINDOW=5:up`. The content of `PREVIEW_WINDOW` is passed to the `--preview-window` option, so check out the fzf manual for further details.

## Extending the launcher

In addition to desktop application entries and binaries, you can extend `sway-launcher-desktop` with custom item providers.
It will read the configuration of custom item providers from `$HOME/.config/sway-launcher-desktop/providers.conf`.
The structure looks like this:

```
[my-provider]
list_cmd=echo -e 'my-custom-entry\034my-provider\034  My custom provider'
preview_cmd=echo -e 'This is the preview of {1}'
launch_cmd=notify-send 'I am now launching {1}'
purge_cmd=command -v '{1}' || exit 43
```

The `list_cmd` generated the list of entries. For each entry, it has to print the following columns, separated by the `\034` field separator character:
1. The item to launch. This will get passed to `preview_cmd` and `launch_cmd` as `{1}`
2. The name of your provider (the same as what what you put inside the brackets, so `my-provider` in this example)
3. The text that appears in the `fzf` window. You might want to prepend it with a glyph and add some color via ANSI escape codes
4. (optional) Metadata that you can pass to `preview_cmd` and `launch_cmd` as `{2}`. For example, this is used to specify a specific Desktop Action inside a .desktop file

The `preview_cmd` renders the contents of the `fzf` preview panel. You can use the template variable `{1}` in your command, which will be substituted with the value of the selected item.

The `launch_cmd` is fired when the user has selected one of the provider's entries.

The `purge_cmd` is used as part of the `purge` function. It tests any entry of a provider. If the test exits with `43`, then the entry will be removed from the history file

Note: Pass the environment variable `PROVIDERS_FILE` to read custom providers from another file than the default `providers.conf`.
The path in `PROVIDERS_FILE` can either be absolute or relative to `${HOME}/.config/sway-launcher-desktop/`.


### Keeping builtin providers
When a custom provider config is used, the default behaviour is to replace the hardcoded builtins. This is not always desirable if you merely wish to *add* something new. Luckily, the built-in providers only call specific functions of the main script, which are also accessible externally.
So you can simply mimick their behaviour by placing this in your config file:

```
[desktop]
list_cmd=/path/to/sway-launcher-desktop.sh list-entries
preview_cmd=/path/to/sway-launcher-desktop.sh describe-desktop "{1}"
launch_cmd=/path/to/sway-launcher-desktop.sh run-desktop '{1}' {2}
purge_cmd=test -f '{1}' || exit 43

[command]
list_cmd=/path/to/sway-launcher-desktop.sh list-commands
preview_cmd=/path/to/sway-launcher-desktop.sh describe-command "{1}"
launch_cmd=$TERMINAL_COMMAND {1}
purge_cmd=command -v '{1}' || exit 43
```

## Launcher history file

By default, `sway-launcher-desktop` stores a history of commands to make frequently used entries available more quickly.
This history is stored in a file in `~/.cache/` (or `$XDG_CACHE_HOME`, if that environment variable is set).
You may change the file path and name by setting the environment variable `HIST_FILE` to the desired path.
Setting the variable to an empty value disables the history feature entirely.

### Housekeeping
After a while, this history might grow and contain some invalid entries due to removed/renamed programs etc.
You can use `./sway-launcher-desktop.sh purge` to identify broken entries and remove them.
Consider adding this command to a cronjob, startup script, or maybe even hook it into your package manager.


## Troubleshooting

Debug information is directed to file descriptor `3` and can be dumped using `./sway-launcher-desktop.sh 3>> ~/sway-launcher-desktop.log`

---

¹ If you want to use this as a keybinding though, this kind of shell substitution will not work inside the config file. [Here's a way to make it work](https://github.com/Biont/sway-launcher-desktop/issues/33#issuecomment-765145677)
