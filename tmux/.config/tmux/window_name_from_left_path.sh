#!/usr/bin/env sh
# Print a compact window label based on the leftmost pane's current directory.
# Used from tmux window-status-format so the tab label is anchored to the
# left-side pane instead of following whichever pane currently has focus.

window_id=$1
[ -n "$window_id" ] || exit 0

path=$(
  tmux list-panes -t "$window_id" -F '#{pane_left} #{pane_top} #{pane_current_path}' 2>/dev/null \
    | LC_ALL=C sort -n -k1,1 -k2,2 \
    | sed -n '1s/^[0-9][0-9]* [0-9][0-9]* //p'
)

[ -n "$path" ] || exit 0

home=${HOME%/}
case "$path" in
  "$home") display_path="~" ;;
  "$home"/*) display_path="~/${path#"$home"/}" ;;
  *) display_path=$path ;;
esac

label=${display_path##*/}
[ -n "$label" ] || label="/"

printf '%s' "$label"
