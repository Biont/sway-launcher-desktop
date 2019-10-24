@test "Exec command is properly extracted from Firefox desktop file" {
  run ../sway-launcher-desktop.sh generate-command data/firefox.desktop
  [ "$status" -eq 0 ]
  [[ "$output" ==  '/usr/lib/firefox/firefox' ]]
}