#!/usr/bin/env bash
# terminal application launcher for sway, using fzf
# Based on: https://gitlab.com/FlyingWombat/my-scripts/blob/master/sway-launcher

shopt -s nullglob
if [[ "$1" == 'describe' ]]; then
  shift
  if [[ $2 == 'command' ]]; then
    title=$1
    readarray arr < <(whatis -l "$1" 2>/dev/null)
    description="${arr[0]}"
    description="${description%*-}"
  else
    title=$(sed -ne '/^Name=/{s/^Name=//;p;q}' "$1")
    description=$(sed -ne '/^Comment=/{s/^Comment=//;p;q}' "$1")
  fi
  echo -e "\033[33m$title\033[0m"
  echo "${description:-No description}"
  exit
fi

HIST_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/${0##*/}-history.txt"

DIRS=(
  /usr/share/applications
  "$HOME/.local/share/applications"
  /usr/local/share/applications
)

GLYPH_COMMAND="  "
GLYPH_DESKTOP="  "

touch "$HIST_FILE"
readarray HIST_LINES <"$HIST_FILE"
FZFPIPE=$(mktemp)
PIDFILE=$(mktemp)
trap 'rm "$FZFPIPE" "$PIDFILE"' EXIT INT

# Append Launcher History, removing usage count
(printf '%s' "${HIST_LINES[@]#* }" >>"$FZFPIPE") &

# Load and append Desktop entries
(
  for dir in "${DIRS[@]}"; do
    [[ -d "$dir" ]] || continue
    awk -v pre="$GLYPH_DESKTOP" -F= '
                BEGINFILE{application=0;block="";a=0}
                /^\[Desktop Entry\]/{block="entry"}
                /^Type=Application/{application=1}
                /^\[Desktop Action/{
                  sub("^\\[Desktop Action ", "");
                  sub("\\]$", "");
                  block="action";
                  a++;
                  actions[a,"key"]=$0
                }
                /^Name=/{
                if(block=="action") {
                    actions[a,"name"]=$2;
                } else {
                    name=$2
                }
                }
                ENDFILE{
                  if (application){
                      print FILENAME "\034desktop\034\033[33m" pre name "\033[0m";
                      if (a>0)
                          for (i=1; i<=a; i++)
                              print FILENAME "\034desktop\034\033[33m" pre name "\033[0m (" actions[i, "name"] ")\034" actions[i, "key"]
                  }
                }' \
      "$dir/"*.desktop </dev/null >>"$FZFPIPE"
    # the empty stdin is needed in case no *.desktop files
  done
) &

# Load and append command list
(
  IFS=:
  read -ra path <<<"$PATH"
  for dir in "${path[@]}"; do
    printf '%s\n' "$dir/"* |
      awk -F / -v pre="$GLYPH_COMMAND" '{print $NF "\034command\034\033[31m" pre "\033[0m" $NF;}'
  done | sort -u >>"$FZFPIPE"
) &

COMMAND_STR=$(
  (
    tail -n +0 -f "$FZFPIPE" &
    echo $! >"$PIDFILE"
  ) |
    fzf +s -x -d '\034' --nth ..3 --with-nth 3 \
      --preview "$0 describe {1} {2}" \
      --preview-window=up:3:wrap --ansi
  kill -9 "$(<"$PIDFILE")" | tail -n1
) || exit 1

[ -z "$COMMAND_STR" ] && exit 1

# update history
for i in "${!HIST_LINES[@]}"; do
  if [[ "${HIST_LINES[i]}" == *" $COMMAND_STR"$'\n' ]]; then
    HIST_COUNT=${HIST_LINES[i]%% *}
    HIST_LINES[$i]="$((HIST_COUNT + 1)) $COMMAND_STR"$'\n'
    match=1
    break
  fi
done
if ! ((match)); then
  HIST_LINES+=("1 $COMMAND_STR"$'\n')
fi

printf '%s' "${HIST_LINES[@]}" | sort -nr >"$HIST_FILE"

command='echo "nope"'
# shellcheck disable=SC2086
readarray -d $'\034' -t PARAMS <<<${COMMAND_STR}
# COMMAND_STR is "<string>\034<type>"
case ${PARAMS[1]} in
desktop)
  # Define the search pattern that specifies the block to search for within the .desktop file
  PATTERN="^\\\\[Desktop Entry\\\\]"
  if [[ -n ${PARAMS[3]} ]]; then
    PATTERN="^\\\\[Desktop Action ${PARAMS[3]%?}\\\\]"
  fi
  # 1. We see a line starting [Desktop, but we're already searching: deactivate search again
  # 2. We see the specified pattern: start search
  # 3. We see an Exec= line during search: remove field codes and set variable
  # 3. We see a Path= line during search: set variable
  # 4. Finally, build command line
  command=$(awk -v pattern="${PATTERN}" -F= '
                BEGIN{a=0;exec=0; path=0}
                   /^\[Desktop/{
                    if(a){
                      a=0
                    }
                   }
                  $0 ~ pattern{
                   a=1
                  }
                  /^Exec=/{
                    if(a && !exec){
                      sub("^Exec=", "");
                      gsub(" ?%[cDdFfikmNnUuv]", "");
                      exec=$0;
                    }
                  }
                  /^Path=/{
                    if(a && !path){
                      path=$2
                    }
                   }

                END{
                  if(path){
                    print "cd " path " &&"
                  }
                  print exec
                }' "${PARAMS[0]}")
  ;;
command)
  command="${PARAMS[0]}"
  ;;
esac
swaymsg -t command exec "$command"
