#!/usr/bin/env bats

@test "Builtin desktop provider works" {
  run  env XDG_CONFIG_HOME=./data/config XDG_DATA_HOME=./data/desktop-files/1 XDG_DATA_DIRS=./data/desktop-files/0 ../sway-launcher-desktop.sh provide desktop
  echo  "OUTPUT:$output"
  echo  "LINES:${#lines[@]}"
  [ "$status" -eq 0 ]
  [[ ${#lines[@]} -gt 2 ]]
}

@test "Builtin command provider works" {
  run  env XDG_CONFIG_HOME=./data/config XDG_DATA_HOME=./data/desktop-files/1 XDG_DATA_DIRS=./data/desktop-files/0 ../sway-launcher-desktop.sh provide command
  echo  "OUTPUT:$output"
  echo  "LINES:${#lines[@]}"
  [ "$status" -eq 0 ]
  [[ ${#lines[@]} -gt 2 ]]
}

@test "Reads custom provider from providers.conf" {
  run  printf %q "$(env XDG_CONFIG_HOME=./data/config/0 ../sway-launcher-desktop.sh provide foo)"
  echo  "OUTPUT:$output"
  [ "$status" -eq 0 ]
  [[ ${output} ==  "$'foo\034foo'" ]]
}

@test "Skips incomplete custom provider from providers.conf" {
  run  printf %q "$(env XDG_CONFIG_HOME=./data/config/0 ../sway-launcher-desktop.sh provide incomplete)"
  echo  "OUTPUT:$output"
  [ "$status" -eq 0 ]
  [[ ${output} ==  "''" ]]
}

@test "Does not use builtin providers when reading from providers.conf" {
  run  printf %q "$(env XDG_CONFIG_HOME=./data/config/0 ../sway-launcher-desktop.sh provide desktop)"
  echo  "OUTPUT:$output"
  [ "$status" -eq 0 ]
  [[ ${output} ==  "''" ]]
}
