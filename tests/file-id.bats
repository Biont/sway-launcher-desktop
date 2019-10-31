@test "Firefox desktop file id is properly generated" {
  run ../sway-launcher-desktop.sh desktop-file-id data/desktop-files/0/applications/firefox.desktop
  echo "EXPECTED: foo-bar.desktop ACTUAL: $output"
  [ "$status" -eq 0 ]
  [[ "$output" ==  'firefox.desktop' ]]
}

@test "Desktop file id foo-bar.desktop from subdirectory is properly generated" {
  run ../sway-launcher-desktop.sh desktop-file-id data/desktop-files/0/applications/foo/bar.desktop
  echo "EXPECTED: foo-bar.desktop ACTUAL: $output"
  [ "$status" -eq 0 ]
  [[ "$output" ==  'foo-bar.desktop' ]]
}
