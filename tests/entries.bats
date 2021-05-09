#!/usr/bin/env bats

@test "Firefox desktop entry and all its actions are extracted" {
  run ../sway-launcher-desktop.sh entries data/desktop-files/0/applications/firefox.desktop
  echo -e "OUTPUT:\n$output"
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ data/desktop-files/0/applications/firefox.desktop ]]
  [[ ${lines[0]} =~ ^data/desktop-files/0/applications/firefox.desktop.*Firefox ]]
  [[ ${lines[1]} =~ ^data/desktop-files/0/applications/firefox.desktop.*Firefox.*(New Window).*new-window ]]
  [[ ${lines[2]} =~ ^data/desktop-files/0/applications/firefox.desktop.*Firefox.*(New Private Window).*new-private-window ]]
}

@test "Inkscape desktop entry and all its actions are extracted" {
  run ../sway-launcher-desktop.sh entries data/desktop-files/0/applications/org.inkscape.Inkscape.desktop
  echo -e "OUTPUT:\n$output"
  [ "$status" -eq 0 ]
  [[ ${lines[0]} =~ data/desktop-files/0/applications/org.inkscape.Inkscape.desktop ]]
  [[ ${lines[0]} =~ ^data/desktop-files/0/applications/org.inkscape.Inkscape.desktop.*Inkscape ]]
  [[ ${lines[1]} =~ ^data/desktop-files/0/applications/org.inkscape.Inkscape.desktop.*Inkscape.*(New.*Drawing).* ]]
}

@test "Wildcard expansion works for extraction of desktop files" {
  run ../sway-launcher-desktop.sh entries data/desktop-files/0/applications/*.desktop
  [ "$status" -eq 0 ]
  [[ ${#lines[@]} ==  9 ]]
}

@test "Reoccurring desktop file ids are not parsed twice" {
  run ../sway-launcher-desktop.sh entries data/desktop-files/**/*.desktop
    echo "EXPECTED: foo-bar.desktop ACTUAL: $output"
  [ "$status" -eq 0 ]
  [[ ${#lines[@]} ==  9 ]]
}

@test "Hidden desktop entries are ignored" {
  run ../sway-launcher-desktop.sh entries data/desktop-files/0/applications/*vim.desktop
  [ "$status" -eq 0 ]
  [[ ${#lines[@]} == 1 ]]
  [[ ${lines[0]} =~ data/desktop-files/0/applications/nvim.desktop ]]
  [[ ${lines[0]} =~ ^data/desktop-files/0/applications/nvim.desktop.*Neovim.*(New File).*new-file ]]
}
