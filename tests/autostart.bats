#!/usr/bin/env bats

setup() {
   export TERMINAL_COMMAND='urxvt -e'
   export XDG_CONFIG_HOME=./data/autostart-folders/0
   export XDG_CONFIG_DIRS=./data/autostart-folders/1
}

@test "Lists all desktop filenames in autostart directories" {
  run ../sway-launcher-desktop.sh list-autostart
  echo -e "OUTPUT:\n$output"
  [ "$status" -eq 0 ]
  [[ ${#lines[@]} ==  2 ]]
  [[ ${lines[0]} =~ data/autostart-folders/0/autostart/firefox.desktop ]]
  [[ ${lines[1]} =~ data/autostart-folders/1/autostart/htop.desktop ]]
}
