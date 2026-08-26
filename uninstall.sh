#!/usr/bin/env bash
#
# Removes the menu entry, the script and the translations from your home
# directory. A currently active passwordless sudo is left alone — it expires
# through its own timer, or can be switched off by hand with:
#   omarchy sudo passwordless
#
# Installed from a package? Then remove the package and drop the menu entry with
# `omarchy-better-passwordless-sudo --remove-menu` beforehand.

set -euo pipefail

HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN_DST="$HOME/.local/bin/omarchy-better-passwordless-sudo"
DATA_DST="$HOME/.local/share/omarchy-better-passwordless-sudo"

# The markers do not depend on which copy runs, so the one in this checkout can
# remove an entry written by the installed one.
for candidate in "$BIN_DST" "$HERE/bin/omarchy-better-passwordless-sudo"; do
  if [[ -x $candidate ]]; then
    "$candidate" --remove-menu
    break
  fi
done

if [[ -f $BIN_DST ]]; then
  rm -f "$BIN_DST"
  echo "✓ Script removed: $BIN_DST"
else
  echo "· Script was not installed"
fi

if [[ -d $DATA_DST ]]; then
  case "$DATA_DST" in
  */omarchy-better-passwordless-sudo) rm -rf "$DATA_DST"; echo "✓ Translations removed: $DATA_DST" ;;
  *) echo "· unexpected path, left untouched: $DATA_DST" ;;
  esac
else
  echo "· No translations found"
fi

if systemctl is-active --quiet "omarchy-nopasswd-expire-$USER.timer" 2>/dev/null; then
  echo
  echo "Heads up: passwordless sudo is still active right now."
  echo "Switch it off immediately with: omarchy sudo passwordless"
fi
