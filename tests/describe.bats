@test "Name and description of firefox desktop file are properly extracted" {
  run ../sway-launcher-desktop.sh describe data/desktop-files/0/applications/firefox.desktop desktop
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ "Firefox" ]]
  [[ ${lines[1]} =~ "Browse the World Wide Web" ]]
}

@test "Name and description of ls command should be given" {
  run ../sway-launcher-desktop.sh describe ls command
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ "ls" ]]
  [[ ${lines[1]} =~ "list directory contents" ]]
}