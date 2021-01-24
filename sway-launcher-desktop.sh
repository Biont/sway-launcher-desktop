#!/usr/bin/env bash
# terminal application launcher for sway, using fzf
# Based on: https://gitlab.com/FlyingWombat/my-scripts/blob/master/sway-launcher
# https://gist.github.com/Biont/40ef59652acf3673520c7a03c9f22d2a
shopt -s nullglob globstar
set -o pipefail
if ! { exec 0>&3; } 1>/dev/null 2>&1; then
  exec 3>/dev/null # If file descriptor 3 is unused in parent shell, output to /dev/null
fi
# shellcheck disable=SC2154
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
IFS=$'\n\t'
DEL=$'\34'

TERMINAL_COMMAND="${TERMINAL_COMMAND:="$TERM -e"}"
GLYPH_COMMAND="${GLYPH_COMMAND-  }"
GLYPH_DESKTOP="${GLYPH_DESKTOP-  }"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sway-launcher-desktop"
PROVIDERS_FILE="${PROVIDERS_FILE:=providers.conf}"
if [[ "${PROVIDERS_FILE#/}" == "${PROVIDERS_FILE}" ]]; then
  # $PROVIDERS_FILE is a relative path, prepend $CONFIG_DIR
  PROVIDERS_FILE="${CONFIG_DIR}/${PROVIDERS_FILE}"
fi

# Provider config entries are separated by the field separator \034 and have the following structure:
# list_cmd,preview_cmd,launch_cmd
declare -A PROVIDERS
if [ -f "${PROVIDERS_FILE}" ]; then
  eval "$(awk -F= '
  BEGINFILE{ provider=""; }
  /^\[.*\]/{sub("^\\[", "");sub("\\]$", "");provider=$0}
  /^(launch|list|preview)_cmd/{st = index($0,"=");providers[provider][$1] = substr($0,st+1)}
  ENDFILE{
    for (key in providers){
      if(!("list_cmd" in providers[key])){continue;}
      if(!("launch_cmd" in providers[key])){continue;}
      if(!("preview_cmd" in providers[key])){continue;}
      for (entry in providers[key]){
       gsub(/[\x27,\047]/,"\x27\"\x27\"\x27", providers[key][entry])
      }
      print "PROVIDERS[\x27" key "\x27]=\x27" providers[key]["list_cmd"] "\034" providers[key]["preview_cmd"] "\034" providers[key]["launch_cmd"] "\x27\n"
    }
  }' "${PROVIDERS_FILE}")"
  if [[ ! -v HIST_FILE ]]; then
    HIST_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/${0##*/}-${PROVIDERS_FILE##*/}-history.txt"
  fi
else
  PROVIDERS['desktop']="${0} list-entries${DEL}${0} describe-desktop \"{1}\"${DEL}${0} run-desktop '{1}' {2}"
  PROVIDERS['command']="${0} list-commands${DEL}${0} describe-command \"{1}\"${DEL}${TERMINAL_COMMAND} {1}"
  if [[ ! -v HIST_FILE ]]; then
    HIST_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/${0##*/}-history.txt"
  fi
fi
PROVIDERS['user']="exit${DEL}exit${DEL}{1}" # Fallback provider that simply executes the exact command if there were no matches

if [[ -n "${HIST_FILE}" ]]; then
  mkdir -p "${HIST_FILE%/*}" && touch "$HIST_FILE"
  readarray HIST_LINES <"$HIST_FILE"
fi

function describe() {
  # shellcheck disable=SC2086
  readarray -d ${DEL} -t PROVIDER_ARGS <<<${PROVIDERS[${1}]}
  # shellcheck disable=SC2086
  [ -n "${PROVIDER_ARGS[1]}" ] && eval "${PROVIDER_ARGS[1]//\{1\}/${2}}"
}
function describe-desktop() {
  description=$(sed -ne '/^Comment=/{s/^Comment=//;p;q}' "$1")
  echo -e "\033[33m$(sed -ne '/^Name=/{s/^Name=//;p;q}' "$1")\033[0m"
  echo "${description:-No description}"
}
function describe-command() {
  readarray arr < <(whatis -l "$1" 2>/dev/null)
  description="${arr[0]}"
  description="${description#* - }"
  echo -e "\033[33m${1}\033[0m"
  echo "${description:-No description}"
}

function provide() {
  # shellcheck disable=SC2086
  readarray -d ${DEL} -t PROVIDER_ARGS <<<${PROVIDERS[$1]}
  eval "${PROVIDER_ARGS[0]}"
}
function list-commands() {
  IFS=: read -ra path <<<"$PATH"
  for dir in "${path[@]}"; do
    printf '%s\n' "$dir/"* |
      awk -F / -v pre="$GLYPH_COMMAND" '{print $NF "\034command\034\033[31m" pre "\033[0m" $NF;}'
  done | sort -u
}
function list-entries() {
  # Get locations of desktop application folders according to spec
  # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
  IFS=':' read -ra DIRS <<<"${XDG_DATA_HOME-${HOME}/.local/share}:${XDG_DATA_DIRS-/usr/local/share:/usr/share}"
  for i in "${!DIRS[@]}"; do
    if [[ ! -d "${DIRS[i]}" ]]; then
      unset -v 'DIRS[$i]'
    else
      DIRS[$i]="${DIRS[i]}/applications/**/*.desktop"
    fi
  done
  # shellcheck disable=SC2068
  entries ${DIRS[@]}
}
function entries() {
  # shellcheck disable=SC2068
  awk -v pre="$GLYPH_DESKTOP" -F= '
    function desktopFileID(filename){
      sub("^.*applications/", "", filename);
      sub("/", "-", filename);
      return filename
    }
    BEGINFILE{
      application=0;
      block="";
      a=0

      id=desktopFileID(FILENAME)
      if(id in fileIds){
        nextfile;
      }else{
        fileIds[id]=0
      }
    }
    /^\[Desktop Entry\]/{block="entry"}
    /^Type=Application/{application=1}
    /^\[Desktop Action/{
      sub("^\\[Desktop Action ", "");
      sub("\\]$", "");
      block="action";
      a++;
      actions[a,"key"]=$0
    }
    /^\[X-/{
      sub("^\\[X-", "");
      sub("\\]$", "");
      block="action";
      a++;
      actions[a,"key"]=$0
    }
    /^Name=/{ (block=="action")? actions[a,"name"]=$2 : name=$2 }
    ENDFILE{
      if (application){
          print FILENAME "\034desktop\034\033[33m" pre name "\033[0m";
          if (a>0)
              for (i=1; i<=a; i++)
                  print FILENAME "\034desktop\034\033[33m" pre name "\033[0m (" actions[i, "name"] ")\034" actions[i, "key"]
      }
    }' \
    $@ </dev/null
  # the empty stdin is needed in case no *.desktop files
}
function run-desktop() {
  CMD="$("${0}" generate-command "$@" 2>&3)"
  echo "Generated Launch command from .desktop file: ${CMD}" >&3
  bash -c "${CMD}"
}
function generate-command() {
  # Define the search pattern that specifies the block to search for within the .desktop file
  PATTERN="^\\\\[Desktop Entry\\\\]"
  if [[ -n $2 ]]; then
    PATTERN="^\\\\[Desktop Action ${2}\\\\]"
  fi
  echo "Searching for pattern: ${PATTERN}" >&3
  # 1. We see a line starting [Desktop, but we're already searching: deactivate search again
  # 2. We see the specified pattern: start search
  # 3. We see an Exec= line during search: remove field codes and set variable
  # 3. We see a Path= line during search: set variable
  # 4. Finally, build command line
  awk -v pattern="${PATTERN}" -v terminal_cmd="${TERMINAL_COMMAND}" -F= '
    BEGIN{a=0;exec=0;path=0}
       /^\[Desktop/{
        if(a){ a=0 }
       }
      $0 ~ pattern{ a=1 }
      /^Terminal=/{
        sub("^Terminal=", "");
        if ($0 == "true") { terminal=1 }
      }
      /^Exec=/{
        if(a && !exec){
          sub("^Exec=", "");
          gsub(" ?%[cDdFfikmNnUuv]", "");
          exec=$0;
        }
      }
      /^Path=/{
        if(a && !path){ path=$2 }
       }
    END{
      if(path){ printf "cd " path " && " }
      if (terminal){ printf terminal_cmd " " }
      print exec
    }' "$1"
}

function autostart() {
  for application in $(list-autostart); do
    (exec setsid /bin/sh -c "$(run-desktop "${application}")" &>/dev/null &)
  done
}

function list-autostart() {
  # Get locations of desktop application folders according to spec
  # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
  IFS=':' read -ra DIRS <<<"${XDG_CONFIG_HOME-${HOME}/.config}:${XDG_CONFIG_DIRS-/etc/xdg}"
  for i in "${!DIRS[@]}"; do
    if [[ ! -d "${DIRS[i]}" ]]; then
      unset -v 'DIRS[$i]'
    else
      DIRS[$i]="${DIRS[i]}/autostart/*.desktop"
    fi
  done

  # shellcheck disable=SC2068
  awk -v pre="$GLYPH_DESKTOP" -F= '
    function desktopFileID(filename){
      sub("^.*autostart/", "", filename);
      sub("/", "-", filename);
      return filename
    }
    BEGINFILE{
      application=0;
      block="";
      a=0

      id=desktopFileID(FILENAME)
      if(id in fileIds){
        nextfile;
      }else{
        fileIds[id]=0
      }
    }
    /^\[Desktop Entry\]/{block="entry"}
    /^Type=Application/{application=1}
    /^Name=/{ iname=$2 }
    ENDFILE{
      if (application){
          print FILENAME;
      }
    }' \
    ${DIRS[@]} </dev/null
}

case "$1" in
describe | describe-desktop | describe-command | entries | list-entries | list-commands | list-autostart | generate-command | autostart | run-desktop | provide)
  "$@"
  exit
  ;;
esac
echo "Starting launcher instance with the following providers:" "${!PROVIDERS[@]}" >&3

FZFPIPE=$(mktemp -u)
mkfifo "$FZFPIPE"
trap 'rm "$FZFPIPE"' EXIT INT

# Append Launcher History, removing usage count
(printf '%s' "${HIST_LINES[@]#* }" >>"$FZFPIPE") &

# Iterate over providers and run their list-command
for PROVIDER_NAME in "${!PROVIDERS[@]}"; do
  (bash -c "${0} provide ${PROVIDER_NAME}" >>"$FZFPIPE") &
done

readarray -t COMMAND_STR <<<$(
  fzf --ansi +s -x -d '\034' --nth ..3 --with-nth 3 \
    --print-query \
    --preview "$0 describe {2} {1}" \
    --preview-window=up:2:noborder \
    --no-multi --cycle \
    --prompt="${GLYPH_PROMPT-# }" \
    --header='' --no-info --margin='1,2' \
    --color='16,gutter:-1' \
    <"$FZFPIPE"
) || exit 1
# Get the last line of the fzf output. If there were no matches, it contains the query which we'll treat as a custom command
# If there were matches, it contains the selected item
COMMAND_STR=$(printf '%s\n' "${COMMAND_STR[@]: -1}")
# We still need to format the query to conform to our fallback provider.
# We check for the presence of field separator character to determine if we're dealing with a custom command
if [[ $COMMAND_STR != *$'\034'* ]]; then
    COMMAND_STR="${COMMAND_STR}"$'\034user\034'"${COMMAND_STR}"$'\034'
    SKIP_HIST=1 # I chose not to include custom commands in the history. If this is a bad idea, open an issue please
fi

[ -z "$COMMAND_STR" ] && exit 1

if [[ -n "${HIST_FILE}" && ! "$SKIP_HIST" ]]; then
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
fi

# shellcheck disable=SC2086
readarray -d $'\034' -t PARAMS <<<${COMMAND_STR}
# shellcheck disable=SC2086
readarray -d ${DEL} -t PROVIDER_ARGS <<<${PROVIDERS[${PARAMS[1]}]}
# Substitute {1}, {2} etc with the correct values
COMMAND=${PROVIDER_ARGS[2]//\{1\}/${PARAMS[0]}}
COMMAND=${COMMAND//\{2\}/${PARAMS[3]}}
COMMAND=${COMMAND%%[[:space:]]}

if [ -t 1 ]; then
  echo "Launching command: ${COMMAND}" >&3
  setsid /bin/sh -c "${COMMAND}" >&/dev/null </dev/null &
  sleep 0.01
else
  echo "${COMMAND}"
fi
