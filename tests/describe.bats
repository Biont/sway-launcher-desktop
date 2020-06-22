@test "Name and description of firefox desktop file are properly extracted" {
  run env XDG_CONFIG_HOME=./data/config ../sway-launcher-desktop.sh describe desktop ./data/desktop-files/0/applications/firefox.desktop
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ "Firefox" ]]
  [[ ${lines[1]} =~ "Browse the World Wide Web" ]]
}

@test "Desktop file names containing single quotes can be processed" {
  run env XDG_CONFIG_HOME=./data/config ../sway-launcher-desktop.sh describe desktop "./data/desktop-files/0/applications/Sid Meier's Civilization IV.desktop"
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ "Sid Meier's Civilization IV" ]]
  [[ ${lines[1]} =~ "Play Civ5" ]]
}

@test "Name and description of ls command should be given" {
  run env XDG_CONFIG_HOME=./data/config ../sway-launcher-desktop.sh describe command ls
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ "ls" ]]
  [[ ${lines[1]} =~ "list directory contents" ]]
}
