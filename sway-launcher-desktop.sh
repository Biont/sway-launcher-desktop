#!/usr/bin/env bash
# terminal application launcher for sway, using fzf
# Based on: https://gitlab.com/FlyingWombat/my-scripts/blob/master/sway-launcher

HIST_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/${0##*/}-history.txt"

DIRS=(
/usr/share/applications
~/.local/share/applications
/usr/local/share/applications
)

GLYPH_COMMAND="  "
GLYPH_DESKTOP="  "

touch "$HIST_FILE"
# Filter DIRS array for directories that actually exist. Append *.desktop to remaining elements
for i in "${!DIRS[@]}" ; do
	if [[ ! -d "${DIRS[i]}" ]]; then
		unset -v 'DIRS[$i]'
	else
		DIRS[$i]="${DIRS[i]}/*.desktop"
	fi
done
DIRS=("${DIRS[@]}")

HIST_FILE_CONTENT=$(< "$HIST_FILE")

function createPreview(){
	DESCRIPTION='No description'
	if [[ $2 == 'command' ]]; then
		TITLE=$1
		DESCRIPTION=$(whatis -l "$1" 2>/dev/null | head -n1 | sed -n -e 's/^.*\(.*\).*\-//p')
	else
		TITLE=$(grep ^Name= "$1" | head -n1 | awk -F= '{print $2}')
		DESCRIPTION=$(grep Comment= "$1" | awk -F= '{print $2}')
    fi
    echo -e "\033[33m $TITLE \033[0m"
    echo "$DESCRIPTION"
}
export -f createPreview

FZFPIPE=$(mktemp)

# Append Launcher History, removing usage count
(echo "$HIST_FILE_CONTENT" | sed -n -e 's/^[0-9]* //p' >> "$FZFPIPE" )&

# Load and append Desktop entries
# shellcheck disable=2068
(grep -roP "Type=Application" ${DIRS[@]} |
 awk -F : '{print $1}' | 
 sort -u | 
 xargs -d "\n" grep -oP "(?<=Name=).*" | 
 awk -F : -v pre="$GLYPH_DESKTOP"  '{print $1 "|desktop|\033[33m" pre "\033[0m" $2}' >> "$FZFPIPE" )&

# Load and append command list
# shellcheck disable=2086
({ IFS=:; ls -H $PATH; } | grep -v '/.*' | sort -u | awk -v pre="$GLYPH_COMMAND" '{print $1 "|command|\033[31m" pre "\033[0m" $1 }' >> "$FZFPIPE" )&

COMMAND_STR=$( (tail -f "$FZFPIPE" & echo $! > pid) |
  fzf +x +s -d '\|' --nth ..3 --with-nth 3.. --preview 'createPreview {1} {2}' --preview-window=up:3:wrap --ansi ; kill -9 "$(<pid)" |
  tail -n1) || exit 1


[ -z "$COMMAND_STR" ] && exit 1


# get full line from history (with count number)
HIST_LINE=$(echo "$HIST_FILE_CONTENT" | grep -Pe "^[0-9]+ \Q$COMMAND_STR\E$")
# echo "Hist Line: $HIST_LINE"



if [ "$HIST_LINE" == "" ]; then
    HIST_COUNT=1
else
    # Increment usage count
    HIST_COUNT=$(echo "$HIST_LINE" | sed -E 's/^([0-9]+) .+$/\1/')
    ((HIST_COUNT++))
    # delete line, to add updated later
    HIST_FILE_CONTENT=$(echo "$HIST_FILE_CONTENT" | \
	grep --invert-match -Pe "^[0-9]+ \Q$COMMAND_STR\E$")
fi

# update history
update_line="${HIST_COUNT} ${COMMAND_STR}"
echo -e "${update_line}\n${HIST_FILE_CONTENT}" | \
    sort --numeric-sort --reverse > "$HIST_FILE"

command='echo "nope"'

case $(echo "$COMMAND_STR" | awk -F'|' '{print $2}') in
desktop)
  file=$(echo "$COMMAND_STR" | awk -F '|' '{print $1}')
  command=$(grep Exec "$file" | awk -F'=' '{print $2}')
  ;;

command)
  command=$(echo "$COMMAND_STR" | awk -F '|' '{print $1}')
  ;;

esac

swaymsg -t command exec "$command"
