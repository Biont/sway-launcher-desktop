#!/usr/bin/env bats

setup() {
   export TERMINAL_COMMAND='urxvt -e'
   export XDG_DATA_HOME=./data/desktop-files/0
   export SLD_DESKTOP_ROOT="$XDG_DATA_HOME/applications/"
   export XDG_CACHE_HOME=$BATS_TEST_TMPDIR
   export XDG_CONFIG_HOME=./data/autostart-folders/0
   export XDG_CONFIG_DIRS=./data/autostart-folders/1
   export SLD_HIST_FILE="$BATS_TEST_TMPDIR/sway-launcher-desktop.sh-history.txt"
   touch "$SLD_HIST_FILE"

   echo "1 ${SLD_DESKTOP_ROOT}firefox.desktopdesktop  Firefox" >> "$SLD_HIST_FILE"
   echo "1 ${SLD_DESKTOP_ROOT}cjsdalkcnjsaddesktop  I wanna be purged" >> "$SLD_HIST_FILE"
   echo "1 awkcommand  awk" >> "$SLD_HIST_FILE"
   echo "1 xksdkasjkslajdslakcommand  I wanna be purged" >> "$SLD_HIST_FILE"
   echo "1 xksdkasjkslajdslakcommand  I wanna be purged too" >> "$SLD_HIST_FILE"
}

@test "Purge command removes invalid entries" {
  run ../sway-launcher-desktop.sh purge
  readarray HIST_LINES <"$SLD_HIST_FILE"
#  cat "$SLD_HIST_FILE"
  echo "$output"
  [ "$status" -eq 0 ]
  [[ ${#HIST_LINES[@]} ==  2 ]]
}
