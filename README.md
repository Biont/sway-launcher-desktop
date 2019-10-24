[![Build Status](https://travis-ci.org/Biont/sway-launcher-desktop.svg?branch=master)](https://travis-ci.org/Biont/sway-launcher-desktop)
# sway-launcher-desktop

This is a launcher menu made for the Sway window manager made with bash and the amazing [fzf](https://github.com/junegunn/fzf).

## Features
- Lists and executes available binaries
- Lists and executes .desktop files (entries as well as actions)
- Shows a preview window containing `whatis` info of binaries and the `Comment=` section of .desktop files
- History support which will highlight recently used entries. (Inspried by [this nice script which inspired me to create my own](https://gitlab.com/FlyingWombat/my-scripts/blob/master/sway-launcher))
- Colored output and glyphs for the different entry types
- Entries are lazily piped into fzf eliminating any lag during startup

## Installation

Make sure you have `fzf` installed and download this repository

Configure it in Sway like this:
```
for_window [class="URxvt" instance="launcher"] floating enable, border pixel 10, sticky enable
set $menu exec urxvt -geometry 55x18 -name launcher -e /path/to/repo/sway-launcher-desktop.sh
bindsym $mod+d exec $menu
```
