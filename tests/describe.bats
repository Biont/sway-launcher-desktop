@test "Name and description of firefox desktop file are properly extracted" {
  run env XDG_CONFIG_HOME=./data/config ../sway-launcher-desktop.sh describe desktop ./data/desktop-files/0/applications/firefox.desktop
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ "Firefox" ]]
  [[ ${lines[1]} =~ "Browse the World Wide Web" ]]
}

@test "Name and description of ls command should be given" {
  run env XDG_CONFIG_HOME=./data/config ../sway-launcher-desktop.sh describe command ls
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ "ls" ]]
  [[ ${lines[1]} =~ "list directory contents" ]]
}
