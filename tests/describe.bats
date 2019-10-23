@test "Name and description of firefox desktop file are properly extracted" {
  run ../sway-launcher-desktop.sh describe data/firefox.desktop
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ "Firefox" ]]
  [[ ${lines[1]} =~ "Browse the World Wide Web" ]]
}

@test "Name and description of awk command should be given" {
  run ../sway-launcher-desktop.sh describe awk command
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ "awk" ]]
  [[ ${lines[1]} =~ "pattern scanning and processing language" ]]
}