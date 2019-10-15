#!/usr/bin/env bash
# terminal application launcher for sway, using fzf
# Based on: https://gitlab.com/FlyingWombat/my-scripts/blob/master/sway-launcher

shopt -s nullglob
if [[ "$1" = 'describe' ]]; then
	shift
	if [[ $2 == 'command' ]]; then
		title=$1
		readarray arr < <(whatis -l "$1" 2>/dev/null)
		description="${arr[0]}"
		description="${description%*-}"
	else
	echo $1
		title=$(sed -ne '/^Name=/{s/^Name=//;p;q}' "$1")
		description=$(sed -ne '/^Comment=/{s/^Comment=//;p;q}' "$1")
    fi
    echo -e "\033[33m $title \033[0m"
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
readarray HIST_LINES < "$HIST_FILE"
FZFPIPE=$(mktemp)
PIDFILE=$(mktemp)
trap 'rm "$FZFPIPE" "$PIDFILE"' EXIT INT

# Append Launcher History, removing usage count
( printf '%s' "${HIST_LINES[@]#* }" >> "$FZFPIPE" ) &

# Load and append Desktop entries
(
	for dir in "${DIRS[@]}"; do
		[[ -d "$dir" ]] || continue
		awk -v pre="$GLYPH_DESKTOP" -F= '
			BEGINFILE{p=0;n=0}
			/^Type=Application/{p=1}
			/^Name=/{if(!n) {n=1;name=$2;}}
			ENDFILE{if (p) print FILENAME "|desktop|\033[33m" pre name "\033[0m";}' \
		"$dir/"*.desktop < /dev/null >> "$FZFPIPE"
		# the empty stdin is needed in case no *.desktop files
	done
) &

# Load and append command list
(
	IFS=:
	read -ra path <<< "$PATH"
	for dir in "${path[@]}"; do
		printf '%s\n' "$dir/"* |
			awk -F / -v pre="$GLYPH_COMMAND" '{print $NF "|command|\033[31m" pre "\033[0m" $NF;}'
	done | sort -u >> "$FZFPIPE"
) &

COMMAND_STR=$(
	(tail -n +0 -f "$FZFPIPE" & echo $! > "$PIDFILE") |
	fzf +s -x -d '\|' --nth ..3 --with-nth 3.. \
		--preview "$0 describe {1} {2}" \
		--preview-window=up:3:wrap --ansi
	kill -9 "$(<"$PIDFILE")" | tail -n1
) || exit 1

[ -z "$COMMAND_STR" ] && exit 1

# update history
for i in "${!HIST_LINES[@]}"; do
	if [[ "${HIST_LINES[i]}" == *" $COMMAND_STR"$'\n' ]]; then
		HIST_COUNT=${HIST_LINES[i]%% *}
		HIST_LINES[$i]="$((HIST_COUNT + 1)) $COMMAND_STR"
		match=1
		break
	fi
done
if ! (( match )); then
	HIST_LINES+=("1 $COMMAND_STR"$'\n')
fi

printf '%s' "${HIST_LINES[@]}" | sort -nr > "$HIST_FILE"

command='echo "nope"'

# COMMAND_STR is "<string>|<type>"
case ${COMMAND_STR#*|} in
desktop*)
	# .desktop files use "%f", "%d" as placeholders for "Open with..."
	command=$(sed -ne 's/%.//; /^Exec/{s/^Exec=//;p;q}' "${COMMAND_STR%%|*}")
	;;
command*)
	command="${COMMAND_STR%%|*}"
	;;
esac

swaymsg -t command exec "$command"
