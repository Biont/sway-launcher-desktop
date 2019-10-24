@test "Firefox desktop entry and all its actions are extracted" {
  run ../sway-launcher-desktop.sh entries data/firefox.desktop
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ data/firefox.desktop ]]
  [[ ${lines[0]} =~ ^data/firefox.desktop.*Firefox ]]
  [[ ${lines[1]} =~ ^data/firefox.desktop.*Firefox.*(New Window).*new-window ]]
  [[ ${lines[2]} =~ ^data/firefox.desktop.*Firefox.*(New Private Window).*new-private-window ]]
}

@test "Wildcard expansion works for extraction of desktop files" {
  run ../sway-launcher-desktop.sh entries data/*.desktop
  [ "$status" -eq 0 ]
  [[ ${#lines[@]} ==  5 ]]
}